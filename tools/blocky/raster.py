"""Pixel masks for the blocky silhouette check: convex polygon fill, a PNG writer and reader, intersection over union.

Standard library only (zlib and struct), so the concept sheet (tools/blocky/sheet.py) writes its view masks without Pillow and the Blender build
(tools/blender/blocky_build.py, whose Python has no Pillow) reads them back. A mask is a bytearray of width * height bytes, 1 where the shape is.
Pixels are sampled at their centres, row 0 at the top.
"""
from __future__ import annotations

import struct
import zlib


def hull(points):
    """Convex hull (Andrew's monotone chain), counter-clockwise, no repeated end point."""
    pts = sorted(set((round(p[0], 9), round(p[1], 9)) for p in points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def fill_convex(mask, width, height, poly, value=1):
    """Set every pixel whose centre lies inside the convex polygon `poly` (pixel coordinates, x right, y down)."""
    if len(poly) < 3:
        return
    ys = [p[1] for p in poly]
    y0 = max(0, int(min(ys) - 0.5))
    y1 = min(height - 1, int(max(ys) + 0.5))
    n = len(poly)
    for row in range(y0, y1 + 1):
        yc = row + 0.5
        xs = []
        for i in range(n):
            (ax, ay), (bx, by) = poly[i], poly[(i + 1) % n]
            if (ay <= yc < by) or (by <= yc < ay):
                xs.append(ax + (yc - ay) * (bx - ax) / (by - ay))
        if len(xs) < 2:
            continue
        left, right = min(xs), max(xs)
        c0 = max(0, _ceil(left - 0.5))            # the first column whose centre is at or right of `left`
        c1 = min(width - 1, _ceil(right - 0.5) - 1)  # the last column whose centre is left of `right`
        base = row * width
        for col in range(c0, c1 + 1):
            mask[base + col] = value


def _ceil(v):
    i = int(v)
    return i if i >= v else i + 1


def iou(a, b):
    inter = union = 0
    for x, y in zip(a, b):
        if x or y:
            union += 1
            if x and y:
                inter += 1
    return inter / union if union else 0.0


def write_png(path, width, height, data, channels=1):
    """Write 8-bit greyscale (1), RGB (3) or RGBA (4) rows; `data` is width * height * channels bytes, row 0 at the top."""
    colour = {1: 0, 2: 4, 3: 2, 4: 6}[channels]
    stride = width * channels
    raw = b"".join(b"\x00" + bytes(data[r * stride:(r + 1) * stride]) for r in range(height))

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, colour, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as fh:
        fh.write(png)


def mask_png(path, width, height, mask):
    """A mask as a black shape on white (what the board's silhouette strip shows)."""
    write_png(path, width, height, bytes(0 if v else 255 for v in mask), 1)


def read_png(path):
    """(width, height, channels, bytearray) of an 8-bit, non-interlaced greyscale, grey+alpha, RGB or RGBA PNG (all five row filters)."""
    with open(path, "rb") as fh:
        blob = fh.read()
    if blob[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG: %s" % path)
    pos, idat, head = 8, b"", None
    while pos < len(blob):
        length = struct.unpack(">I", blob[pos:pos + 4])[0]
        kind = blob[pos + 4:pos + 8]
        body = blob[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            head = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
    width, height, depth, colour, _, _, interlace = head
    if depth != 8 or interlace:
        raise ValueError("only 8-bit non-interlaced PNGs: %s" % path)
    channels = {0: 1, 4: 2, 2: 3, 6: 4}.get(colour)
    if channels is None:
        raise ValueError("unsupported PNG colour type %d: %s" % (colour, path))
    raw = zlib.decompress(idat)
    stride = width * channels
    out = bytearray(height * stride)
    prev = bytearray(stride)
    i = 0
    for r in range(height):
        kind = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            left = line[x - channels] if x >= channels else 0
            up = prev[x]
            ul = prev[x - channels] if x >= channels else 0
            if kind == 1:
                line[x] = (line[x] + left) & 255
            elif kind == 2:
                line[x] = (line[x] + up) & 255
            elif kind == 3:
                line[x] = (line[x] + (left + up) // 2) & 255
            elif kind == 4:
                p = left + up - ul
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - ul)
                pred = left if pa <= pb and pa <= pc else (up if pb <= pc else ul)
                line[x] = (line[x] + pred) & 255
        out[r * stride:(r + 1) * stride] = line
        prev = line
    return width, height, channels, out


def png_mask(path, use_alpha=None, threshold=128):
    """A mask from a PNG: by alpha when it has one (a render with a transparent film), else dark pixels (a black shape on white)."""
    width, height, channels, data = read_png(path)
    if use_alpha is None:
        use_alpha = channels in (2, 4)
    out = bytearray(width * height)
    for k in range(width * height):
        px = data[k * channels:(k + 1) * channels]
        out[k] = 1 if (px[-1] >= threshold if use_alpha else px[0] < threshold) else 0
    return width, height, out
