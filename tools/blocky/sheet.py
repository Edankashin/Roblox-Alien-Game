#!/usr/bin/env python3
"""The orthographic concept sheet of a blocky creature, drawn from its spec note (tools/blocky/spec.py), for the Claude Design canvas.

One layout, two outputs from the same geometry:
  <Id>_sheet.svg        flat rectangles and polygons, labels as <text>: the board Claude Design places and Ethan comments on
  <Id>_sheet.png        the same sheet drawn with Pillow (when Pillow is installed), for the vault and the review sheet
  <Id>_mask_<view>.png  the black shape of each view at 256 px in the view's frame, for the build's silhouette overlap (standard library)
  <Id>_frames.json      the frame of each view (centre and side in studs) that the masks and the Blender cameras share

The sheet: front, right, top and back views at one scale on a shared baseline over a stud grid (major 1 stud, minor 0.25), the total height
dimensioned, a 5-stud blocky avatar on the same baseline for scale, the face drawn on the head in the front view, the parts table, the palette
with roles and their greyscale values, the face as a pixel grid, and a 64 px silhouette strip.

Views (the creature faces -Z, its right is +X): front looks from -Z (screen right = -X), right looks from +X (the face is on the right),
top looks down with the front at the bottom, back looks from +Z.

  python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Mossbop.md --out /scratch/blocky/Mossbop
"""
from __future__ import annotations

import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import raster  # noqa: E402
import spec as S  # noqa: E402

VIEWS = ("front", "right", "top", "back")
MASK_SIZE = 256
STRIP_SIZE = 64
TIER_HEX = {"Common": "#B0B0B0", "Uncommon": "#57F96C", "Rare": "#3B82F6", "Epic": "#C026D3", "Legendary": "#F59E0B", "Cosmic": "#EC4899", "Secret": "#111111"}
# The scale figure: a generic 5-stud blocky avatar (legs 2, torso 2, head 1), as spec parts so the sheet and Blender draw the same thing.
AVATAR = [
    {"name": "leg", "size": [1.0, 2.0, 1.0], "at": [0.5, 1.0, 0.0], "mirror": "x"},
    {"name": "torso", "size": [2.0, 2.0, 1.0], "at": [0.0, 3.0, 0.0]},
    {"name": "arm", "size": [1.0, 2.0, 1.0], "at": [1.5, 3.0, 0.0], "mirror": "x"},
    {"name": "head", "size": [1.25, 1.0, 1.25], "at": [0.0, 4.5, 0.0]},
]
AVATAR_HEX = "#8A8F9C"
PAPER, PANEL, INK, MUTED = "#F7F3EA", "#FFFFFF", "#1B1F3B", "#6B6F80"
GRID_MINOR, GRID_MAJOR, GROUND = "#ECE7DD", "#D2CABB", "#1B1F3B"


def avatar_parts():
    return S.expand([S.normalise(dict(p, slot="Body")) for p in AVATAR])


# ------------------------------------------------------------------------------------------------ projection
def project(view, v):
    """(u, v) on the view plane: u to the right of the image, v up."""
    x, y, z = v
    if view == "front":
        return (-x, y)
    if view == "right":
        return (-z, y)
    if view == "back":
        return (x, y)
    if view == "top":
        return (-x, z)
    raise ValueError(view)


def depth(view, v):
    """Distance away from the viewer (bigger is farther): the painter draws far first."""
    x, y, z = v
    return {"front": z, "right": -x, "back": -z, "top": -y}[view]


def part_polygon(view, part):
    verts, _ = S.part_mesh(part)
    return raster.hull([project(view, v) for v in verts])


def view_items(spec, view, parts=None):
    """[(depth, kind, payload)] far to near: ('part', (part, polygon)) and, on the front view, ('face', cells) right in front of the head."""
    parts = parts if parts is not None else S.expand(spec["parts"])
    items = []
    for p in parts:
        verts, _ = S.part_mesh(p)
        near = min(depth(view, v) for v in verts)
        centre = sum(depth(view, v) for v in verts) / len(verts)
        items.append((near, centre, "part", (p, part_polygon(view, p))))
    host = S.face_host(spec)
    if view == "front" and host is not None and spec.get("face"):
        near = host["at"][2] - host["size"][2] / 2
        items.append((near - 1e-6, near - 1e-6, "face", face_cells(spec, host)))
    # far to near by each part's nearest point (a thin band on a big mass is drawn after the mass only when it stands proud of it),
    # the centre breaking ties
    items.sort(key=lambda t: (-t[0], -t[1]))
    return [(d, kind, payload) for d, _, kind, payload in items]


def plate_cells(spec, frame=0):
    """B46: [(u0, v0, u1, v1, hex)] of every drawn pixel of the face plate's frame `frame` (the open eyes by default), front-view coordinates."""
    E = S._eyes_lib()
    host = S.face_host(spec)
    lay = S.plate_layout(spec)
    rows = E.plate_frames(spec["eyes"], host)[frame][1]
    colours = E.resolve_colours(spec["eyes"], S.palette(spec))
    px = 1.0 / lay["density"]
    (cx, cy), (w, h) = lay["centre"], lay["size"]
    out = []
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if ch == ".":
                continue
            u0 = -(cx + w / 2) + c * px
            v1 = cy + h / 2 - r * px
            out.append((u0, v1 - px, u0 + px, v1, colours[ch]))
    return out


def face_cells(spec, host):
    """[(u0, v0, u1, v1, hex)] of every non-body face cell, in front-view coordinates (column 0 at the viewer's left, the creature's +X).
    On the B46 format the head's front is plain body cells and the face is the plate's open frame."""
    if S.is_b46(spec):
        return plate_cells(spec)
    face = spec["face"]
    rows = face["rows"]
    cols = len(rows[0])
    w, h = host["size"][0], host["size"][1]
    cell = w / cols
    x_max = host["at"][0] + w / 2
    y_top = host["at"][1] + h / 2
    body_role = S.SLOT_ROLE[host["slot"]]
    out = []
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            if str(face["legend"].get(ch)) == body_role:
                continue
            u0 = -x_max + c * cell
            v1 = y_top - r * cell
            out.append((u0, v1 - cell, u0 + cell, v1, S.face_colour(spec, ch)))
    return out


def extents(view, parts):
    us, vs = [], []
    for p in parts:
        for v in S.part_mesh(p)[0]:
            u, w = project(view, v)
            us.append(u)
            vs.append(w)
    return min(us), max(us), min(vs), max(vs)


def frames(spec):
    """{view: {'centre': [u, v], 'side': studs}}: the square each view's mask and Blender camera share."""
    parts = S.expand(spec["parts"])
    out = {}
    for view in VIEWS:
        u0, u1, v0, v1 = extents(view, parts)
        side = max(u1 - u0, v1 - v0) * 1.1 + 0.25
        out[view] = {"centre": [round((u0 + u1) / 2, 6), round((v0 + v1) / 2, 6)], "side": round(side, 6)}
    return out


def view_mask(spec, view, frame=None, size=MASK_SIZE):
    """The black shape of one view as a bytearray (size * size), sampled at pixel centres inside the view's frame."""
    frame = frame or frames(spec)[view]
    cu, cv = frame["centre"]
    side = frame["side"]
    px = size / side
    mask = bytearray(size * size)
    for p in S.expand(spec["parts"]):
        poly = [((u - cu + side / 2) * px, (cv + side / 2 - v) * px) for u, v in part_polygon(view, p)]
        raster.fill_convex(mask, size, size, poly)
    return mask


# ------------------------------------------------------------------------------------------------ canvases
def _shade(hexcol, f):
    r, g, b = S.hex_rgb(hexcol)
    return "#%02X%02X%02X" % tuple(max(0, min(255, int(c * f))) for c in (r, g, b))


def _grey(hexcol):
    v = S.lstar(hexcol) / 100.0
    lin = ((v * 100 + 16) / 116) ** 3 if v * 100 > 8 else v * 100 / 903.3
    srgb = 12.92 * lin if lin <= 0.0031308 else 1.055 * lin ** (1 / 2.4) - 0.055
    g = max(0, min(255, int(round(srgb * 255))))
    return "#%02X%02X%02X" % (g, g, g)


class SvgCanvas:
    def __init__(self, width, height):
        self.width, self.height = width, height
        self.items = []

    def rect(self, x, y, w, h, fill, stroke=None, sw=1.0):
        s = ' stroke="%s" stroke-width="%.2f"' % (stroke, sw) if stroke else ""
        self.items.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s"%s/>' % (x, y, w, h, fill, s))

    def poly(self, pts, fill, stroke=None, sw=1.0):
        s = ' stroke="%s" stroke-width="%.2f" stroke-linejoin="round"' % (stroke, sw) if stroke else ""
        self.items.append('<polygon points="%s" fill="%s"%s/>' % (" ".join("%.2f,%.2f" % p for p in pts), fill, s))

    def line(self, x1, y1, x2, y2, stroke, sw=1.0):
        self.items.append('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="%s" stroke-width="%.2f"/>' % (x1, y1, x2, y2, stroke, sw))

    def text(self, x, y, s, size=14, fill=INK, bold=False, anchor="start"):
        esc = str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        a = {"start": "start", "middle": "middle", "end": "end"}[anchor]
        self.items.append('<text x="%.2f" y="%.2f" font-family="Helvetica, Arial, sans-serif" font-size="%d"%s fill="%s" text-anchor="%s">%s</text>' % (
            x, y, size, ' font-weight="bold"' if bold else "", fill, a, esc))

    def group(self, label):
        self.items.append("<!-- %s -->" % label)

    def save(self, path):
        head = '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (self.width, self.height, self.width, self.height)
        pathlib.Path(path).write_text(head + "\n" + "\n".join(self.items) + "\n</svg>\n", encoding="utf-8")


class PilCanvas:
    """The same calls drawn with Pillow at 2x and reduced, so edges and text are smooth."""
    FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf"
    K = 2

    def __init__(self, width, height):
        from PIL import Image, ImageDraw  # noqa: PLC0415
        self.Image = Image
        self.width, self.height = width, height
        self.img = Image.new("RGB", (width * self.K, height * self.K), PAPER)
        self.d = ImageDraw.Draw(self.img)
        self.fonts = {}

    def _font(self, size, bold):
        from PIL import ImageFont  # noqa: PLC0415
        key = (size, bold)
        if key not in self.fonts:
            try:
                self.fonts[key] = ImageFont.truetype(self.FONT % ("Bold" if bold else "Regular"), size * self.K)
            except OSError:
                self.fonts[key] = ImageFont.load_default()
        return self.fonts[key]

    def rect(self, x, y, w, h, fill, stroke=None, sw=1.0):
        k = self.K
        self.d.rectangle([x * k, y * k, (x + w) * k - 1, (y + h) * k - 1], fill=fill, outline=stroke, width=max(1, int(sw * k)) if stroke else 0)

    def poly(self, pts, fill, stroke=None, sw=1.0):
        k = self.K
        q = [(px * k, py * k) for px, py in pts]
        self.d.polygon(q, fill=fill)
        if stroke:
            self.d.line(q + [q[0]], fill=stroke, width=max(1, int(sw * k)), joint="curve")

    def line(self, x1, y1, x2, y2, stroke, sw=1.0):
        k = self.K
        self.d.line([(x1 * k, y1 * k), (x2 * k, y2 * k)], fill=stroke, width=max(1, int(sw * k)))

    def text(self, x, y, s, size=14, fill=INK, bold=False, anchor="start"):
        k = self.K
        a = {"start": "ls", "middle": "ms", "end": "rs"}[anchor]
        self.d.text((x * k, y * k), str(s), font=self._font(size, bold), fill=fill, anchor=a)

    def group(self, label):
        pass

    def save(self, path):
        out = self.img.resize((self.width, self.height), self.Image.LANCZOS)
        out.save(path)


# ------------------------------------------------------------------------------------------------ layout
def fmt(v):
    return ("%.4f" % v).rstrip("0").rstrip(".")


def vec(v):
    return "[" + ", ".join(fmt(c) for c in v) + "]"


def layout(spec, width=1800):
    """Everything the sheet needs before drawing: the scale, the panels and the canvas height."""
    parts = S.expand(spec["parts"])
    avatar = avatar_parts()
    ext = {v: extents(v, parts) for v in VIEWS}
    ext["avatar"] = extents("front", avatar)
    pad, gap, margin = 0.5, 0.75, 30
    widths = {v: (ext[v][1] - ext[v][0]) + 2 * pad for v in list(VIEWS) + ["avatar"]}
    height = max(ext["front"][3], 5.0)
    top_depth = ext["top"][3] - ext["top"][2]
    tall = max(height, top_depth) + 2 * pad
    total = sum(widths.values()) + gap * (len(widths) - 1)
    scale = min(130.0, (width - 2 * margin) / total, 560.0 / tall)
    panels, x = {}, margin + (width - 2 * margin - total * scale) / 2
    top_y = 130
    base = top_y + (tall - pad) * scale
    for v in list(VIEWS) + ["avatar"]:
        panels[v] = {"x": x, "w": widths[v] * scale, "u0": ext[v][0] - pad}
        x += (widths[v] + gap) * scale
    return {"parts": parts, "avatar": avatar, "ext": ext, "scale": scale, "panels": panels, "top_y": top_y, "base": base, "tall": tall, "pad": pad,
            "height": ext["front"][3]}


def draw_sheet(spec, canvas_cls, width=1800, overlap=None):
    L = layout(spec, width)
    front = spec["front"]
    parts, s, base, pad = L["parts"], L["scale"], L["base"], L["pad"]
    c_rows = len(spec["parts"])
    table_h = 70 + 18 * c_rows
    right_h = 520 + (len((spec.get("face") or {}).get("rows") or []) * 14 if not S.is_b46(spec) else 260)
    below = base + 70
    height = int(below + max(table_h, right_h) + 40)
    cv = canvas_cls(width, height)
    cv.rect(0, 0, width, height, PAPER)
    counts = S.counts(spec)
    pal = S.palette(spec)
    tier = front.get("tier", "")

    # header
    cv.group("header")
    cv.text(30, 58, "%s  (%s)" % (front.get("name", ""), front.get("id", "")), 34, INK, True)
    cv.rect(30, 74, 132, 28, TIER_HEX.get(tier, "#999999"))
    cv.text(96, 94, str(tier).upper(), 16, "#FFFFFF" if tier not in ("Common", "Uncommon") else INK, True, "middle")
    cv.text(176, 94, "World %s  |  element %s  |  status %s  |  hero: %s" % (front.get("world"), front.get("element", "-"), front.get("status"), front.get("hero")), 16, MUTED)
    stats = "height %.2f studs  |  %d blocks  |  %d triangles  |  bevel %s x %s  |  1 stud = %.0f px" % (
        counts["height"], counts["blocks"], front.get("tris") or counts["tris"], fmt(float(front.get("bevel_width") or 0)), front.get("bevel_segments"), s)
    cv.text(width - 30, 58, stats, 16, INK, True, "end")
    cv.text(width - 30, 86, "Concept sheet drawn from the spec note's parts table (tools/blocky/sheet.py); blocky style rules: Blocky-Style.md", 13, MUTED, False, "end")

    # views
    for view in list(VIEWS) + ["avatar"]:
        P = L["panels"][view]
        cv.group("view " + view)
        top = L["top_y"]
        cv.rect(P["x"], top, P["w"], L["tall"] * s, PANEL, "#DDD6C8", 1)
        u0 = P["u0"]
        to_x = lambda u, P=P, u0=u0: P["x"] + (u - u0) * s  # noqa: E731
        if view == "top":
            v0 = L["ext"]["top"][2] - pad
            to_y = lambda v, v0=v0: base - (v - v0) * s  # noqa: E731
        else:
            to_y = lambda v: base - v * s  # noqa: E731
        # grid: minor every 0.25, major every 1 stud, on the creature's own origin
        n0 = int((u0) * 4) - 1
        n1 = int((u0 + P["w"] / s) * 4) + 1
        for n in range(n0, n1 + 1):
            u = n / 4
            gx = to_x(u)
            if P["x"] < gx < P["x"] + P["w"]:
                cv.line(gx, top, gx, top + L["tall"] * s, GRID_MAJOR if n % 4 == 0 else GRID_MINOR, 1.0 if n % 4 == 0 else 0.6)
        vlo = (L["ext"]["top"][2] - pad) if view == "top" else -pad * 0
        vhi = vlo + L["tall"] * s / s if view == "top" else L["tall"] - pad
        m0, m1 = int(min(vlo, -pad) * 4) - 1, int(vhi * 4) + 4
        for n in range(m0, m1 + 1):
            gy = to_y(n / 4)
            if top < gy < top + L["tall"] * s:
                cv.line(P["x"], gy, P["x"] + P["w"], gy, GRID_MAJOR if n % 4 == 0 else GRID_MINOR, 1.0 if n % 4 == 0 else 0.6)
        if view == "avatar":
            for _, kind, (p, poly) in view_items({"parts": [], "front": {}}, "front", L["avatar"]):
                cv.poly([(to_x(u), to_y(v)) for u, v in poly], AVATAR_HEX, _shade(AVATAR_HEX, 0.7), 1)
            cv.text(P["x"] + P["w"] / 2, to_y(5.0) - 8, "5 studs", 13, MUTED, False, "middle")
        else:
            for _, kind, payload in view_items(spec, view, parts):
                if kind == "part":
                    p, poly = payload
                    hexcol = S.slot_hex(spec, p["slot"])
                    cv.poly([(to_x(u), to_y(v)) for u, v in poly], hexcol, _shade(hexcol, 0.62), 1.0)
                else:
                    for a0, b0, a1, b1, hexcol in payload:
                        cv.rect(to_x(a0), to_y(b1), (a1 - a0) * s, (b1 - b0) * s, hexcol)
        if view != "top":
            cv.line(P["x"], base, P["x"] + P["w"], base, GROUND, 2)
        label = {"front": "FRONT (from -Z)", "right": "RIGHT (from +X)", "top": "TOP (front down)", "back": "BACK (from +Z)", "avatar": "AVATAR"}[view]
        cv.text(P["x"] + P["w"] / 2, base + 26, label, 14, INK, True, "middle")
    # height dimension on the front view
    P = L["panels"]["front"]
    hx = P["x"] + 10
    ytop = base - L["height"] * s
    cv.line(hx, base, hx, ytop, "#C2410C", 1.5)
    cv.line(hx - 6, ytop, hx + 6, ytop, "#C2410C", 1.5)
    cv.line(hx - 6, base, hx + 6, base, "#C2410C", 1.5)
    cv.text(hx + 8, ytop + 16, "H %.2f" % L["height"], 14, "#C2410C", True)

    # parts table
    cv.group("parts table")
    tx, ty = 30, below
    cv.text(tx, ty, "Parts (the note's table; mirror x makes an R and an L)", 18, INK, True)
    heads = [("name", 0), ("slot", 150), ("shape", 245), ("size", 305), ("at", 455), ("rot", 610), ("bevel", 720), ("mirror", 770), ("moves", 830)]
    for h, dx in heads:
        cv.text(tx + dx, ty + 26, h, 13, MUTED, True)
    cv.line(tx, ty + 32, tx + 1000, ty + 32, "#CFC7B8", 1)
    for i, p in enumerate(spec["parts"]):
        y = ty + 50 + i * 18
        if i % 2 == 0:
            cv.rect(tx, y - 13, 1000, 18, "#EFE9DD")
        hexcol = S.slot_hex(spec, p["slot"])
        cv.rect(tx + 134, y - 10, 10, 10, hexcol, _shade(hexcol, 0.6), 0.8)
        cells = [p["name"], p["slot"], p["shape"], vec(p["size"]), vec(p["at"]), vec(p["rot"]) if any(p["rot"]) else "-",
                 "yes" if p["bevel"] else "-", p["mirror"] if p["mirror"] != "none" else "-",
                 (p["moves"] + " @ " + vec(p["pivot"])) if p["moves"] != "none" else "-"]
        for (h, dx), val in zip(heads, cells):
            cv.text(tx + dx, y, val, 12, INK, h == "name")

    # palette
    rx, ry = 1060, below
    cv.group("palette")
    cv.text(rx, ry, "Palette (role, hex, greyscale L*)", 18, INK, True)
    for i, (role, hexcol) in enumerate(pal.items()):
        y = ry + 18 + i * 40
        cv.rect(rx, y, 56, 32, hexcol, _shade(hexcol, 0.6), 1)
        cv.rect(rx + 60, y, 32, 32, _grey(hexcol), "#999999", 1)
        cv.text(rx + 104, y + 21, "%s  %s  L* %.0f" % (role, hexcol, S.lstar(hexcol)), 14, INK)
    # face
    face = spec.get("face") or {}
    rows = face.get("rows") or []
    fy = ry + 18 + len(pal) * 40 + 30
    cv.group("face")
    if S.is_b46(spec):
        fy = _plate_panel(cv, spec, rx, fy)
        rows = []
    else:
        cv.text(rx, fy, "Face: %d x %d cells on %s's front (the house eye)" % (len(rows[0]) if rows else 0, len(rows), face.get("host")), 18, INK, True)
    if rows:
        cell = min(14.0, 300.0 / len(rows[0]))
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                hexcol = S.face_colour(spec, ch)
                cv.rect(rx + c * cell, fy + 14 + r * cell, cell, cell, hexcol, "#00000022" if False else None)
        gx1 = rx + len(rows[0]) * cell
        for c in range(len(rows[0]) + 1):
            cv.line(rx + c * cell, fy + 14, rx + c * cell, fy + 14 + len(rows) * cell, "#FFFFFF", 0.5)
        for r in range(len(rows) + 1):
            cv.line(rx, fy + 14 + r * cell, gx1, fy + 14 + r * cell, "#FFFFFF", 0.5)
        lx = gx1 + 24
        for i, (ch, val) in enumerate((face.get("legend") or {}).items()):
            hexcol = S.face_colour(spec, ch)
            cv.rect(lx, fy + 16 + i * 22, 14, 14, hexcol, "#888888", 0.8)
            cv.text(lx + 22, fy + 28 + i * 22, "%s  %s" % (ch, val), 13, INK)
        fy += 14 + len(rows) * cell
    # silhouette strip
    sy = fy + 44
    cv.group("silhouettes")
    cv.text(rx, sy, "Silhouettes at 64 px (black shape, each view in its own frame)", 18, INK, True)
    fr = frames(spec)
    for i, view in enumerate(VIEWS):
        m = view_mask(spec, view, fr[view], STRIP_SIZE)
        ox, oy = rx + i * 84, sy + 14
        cv.rect(ox, oy, STRIP_SIZE, STRIP_SIZE, "#FFFFFF", "#BBBBBB", 1)
        _mask_rects(cv, m, STRIP_SIZE, ox, oy)
        label = view
        if overlap and view in overlap:
            label = "%s %.2f" % (view, overlap[view])
        cv.text(ox + STRIP_SIZE / 2, oy + STRIP_SIZE + 16, label, 12, MUTED, False, "middle")
    notes_y = sy + 14 + STRIP_SIZE + 46
    for i, line in enumerate(wrap("Element: %s.  VFX: %s" % (front.get("element", "-"), front.get("vfx", "none")), 95)):
        cv.text(rx, notes_y + i * 18, line, 13, INK)
    return cv


def _plate_panel(cv, spec, rx, fy):
    """B46: the face plate's frames (the eye library design, its tier floor, the plate's pixels) on the head colour, as small grids."""
    E = S._eyes_lib()
    eyes = spec["eyes"]
    host = S.face_host(spec)
    lay = S.plate_layout(spec)
    frames = E.plate_frames(eyes, host)
    colours = E.resolve_colours(eyes, S.palette(spec))
    d = E.DESIGNS[eyes["key"]]
    cv.text(rx, fy, "Face plate: `%s` (%s eye), %d x %d px at %d a stud, %d frames" % (eyes["key"], d["tier"], lay["w"], lay["h"], lay["density"],
                                                                                      len(frames)), 18, INK, True)
    body = S.slot_hex(spec, host["slot"])
    cell = min(4.0, 150.0 / lay["w"])
    fw, fh = lay["w"] * cell, lay["h"] * cell
    per_row = max(1, int(560 // (fw + 10)))
    shown = frames[:per_row * 3]
    for i, (name, rows) in enumerate(shown):
        ox = rx + (i % per_row) * (fw + 10)
        oy = fy + 14 + (i // per_row) * (fh + 22)
        cv.rect(ox, oy, fw, fh, body)
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                if ch != ".":
                    cv.rect(ox + c * cell, oy + r * cell, cell, cell, colours[ch])
        cv.text(ox, oy + fh + 13, name, 11, MUTED)
    return fy + 14 + ((len(shown) - 1) // per_row + 1) * (fh + 22)


def wrap(text, width):
    lines, line = [], ""
    for word in str(text).split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = word
        else:
            line = (line + " " + word).strip()
    return lines + ([line] if line else [])


def _mask_rects(cv, mask, size, ox, oy):
    """A mask drawn as horizontal runs (few rectangles, crisp in SVG)."""
    for r in range(size):
        c = 0
        while c < size:
            if mask[r * size + c]:
                c0 = c
                while c < size and mask[r * size + c]:
                    c += 1
                cv.rect(ox + c0, oy + r, c - c0, 1, "#111111")
            else:
                c += 1


def write_all(spec, out, overlap=None):
    out = pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)
    sid = spec["front"]["id"]
    written = []
    draw_sheet(spec, SvgCanvas, overlap=overlap).save(out / ("%s_sheet.svg" % sid))
    written.append(out / ("%s_sheet.svg" % sid))
    try:
        draw_sheet(spec, PilCanvas, overlap=overlap).save(out / ("%s_sheet.png" % sid))
        written.append(out / ("%s_sheet.png" % sid))
    except ImportError:
        print("  (no Pillow: the PNG sheet is skipped; the SVG and the masks are written)")
    fr = frames(spec)
    for view in VIEWS:
        m = view_mask(spec, view, fr[view])
        path = out / ("%s_mask_%s.png" % (sid, view))
        raster.mask_png(path, MASK_SIZE, MASK_SIZE, m)
        written.append(path)
    (out / ("%s_frames.json" % sid)).write_text(json.dumps({"mask_size": MASK_SIZE, "frames": fr}, indent=1), encoding="utf-8")
    written.append(out / ("%s_frames.json" % sid))
    return written


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    out = None
    paths = []
    it = iter(argv)
    for a in it:
        if a == "--out":
            out = next(it)
        else:
            paths.append(a)
    if not paths:
        print(__doc__)
        return 2
    for p in paths:
        spec = S.load(p)
        errors, _ = S.validate(spec)
        if errors:
            print("%s: %d spec errors (run spec.py); drawing anyway" % (p, len(errors)))
        if not out:
            print("--out is required (a scratch folder, or refs/blocky for the vault copies)")
            return 2
        target = out
        ov = spec["front"].get("overlap")
        for w in write_all(spec, target, overlap=dict(zip(VIEWS, ov)) if isinstance(ov, list) and len(ov) == len(VIEWS) else None):
            print("  " + str(w))
    return 0


if __name__ == "__main__":
    sys.exit(main())
