#!/usr/bin/env python3
"""Blocky creature spec notes (docs/vault/07-alien-game/Creatures/<Id>.md): parse, expand mirrors, validate, write counts back.

The note is the single source of truth for the concept sheet (tools/blocky/sheet.py) and the Blender build (tools/blender/blocky_build.py). Its
frontmatter is the roster row (id, name, world, tier, status, height, blocks, tris, palette, roles, hero, artboard, render, glb, ...); its body holds two
fenced ```yaml blocks, one whose root key is `parts` and one whose root key is `face`. The rules checked here are the numbered rules of
docs/vault/06-art-pipelines/Blocky-Style.md; each error names its rule.

Standard library only (no PyYAML: the bpy Python has none), so it imports under system Python, `python3 -I` and Blender's Python alike.

  python3 -I tools/blocky/spec.py docs/vault/07-alien-game/Creatures/Mossbop.md            # parse and validate, print the counts
  python3 -I tools/blocky/spec.py docs/vault/07-alien-game/Creatures/*.md --write          # ... and write blocks and tris into the frontmatter
  python3 -I tools/blocky/spec.py Radish.md --json                                         # the expanded parts as JSON

Space: studs, +Y up, the creature faces -Z (Roblox's front), its right side is +X, feet on y = 0. `at` is a part's centre, `size` its box before
rotation, `rot` degrees about X then Y then Z (Blender's XYZ Euler). Exit 1 when a note has errors.
"""
from __future__ import annotations

import json
import math
import pathlib
import re
import sys

# ------------------------------------------------------------------------------------------------ the numbers (Blocky-Style.md)
GRID = 0.25                 # rule 2: masses on the quarter-stud grid
HALF = 0.125                # rule 2: detail blocks may use the half grid; every face of an unrotated block lies on it
TILT_SNAP = 0.0625          # rule 2: a tilted appendage's centre lies on the sixteenth grid (its faces cannot lie on any grid)
TILT_MIN, TILT_MAX = 10.0, 25.0   # rule 1: an appendage tilts 10 to 25 degrees off a quarter turn, or not at all
BEVEL_SHARE = (0.06, 0.10)  # rule 1: one bevel width, 6 to 10 percent of the smallest side of the bevelled masses
MASSES = (1, 4)             # rule 1: one to four bevelled masses (a Common may be head and body in one)
HEAD_SHARE = (0.40, 0.60)   # rule 2: the face host is 40 to 60 percent of the height
LEG_SHARE = (0.10, 0.25)    # rule 2: the gap under the lowest mass is 10 to 25 percent of the height
TRI_CAP = 2500              # the project's per-creature cap (Character-Pipeline)
MOVERS_MAX = 4              # rule 8: at most four moving objects (each is one more MeshPart and draw call)
FACE_COLS = (16, 32)        # rule 3
INK_LSTAR_MAX = 20.0        # rule 4: the ink is near-black
LSTAR_GAP = {("body", "second"): 15.0, ("body", "accent"): 12.0}   # rule 4: the greyscale check
SLOTS = ("Body", "BodyDark", "Accessory", "Trim", "Glow", "Eye")
SLOT_ROLE = {"Body": "body", "BodyDark": "second", "Accessory": "accent", "Trim": "trim", "Glow": "glow", "Eye": "ink"}
ROLES = ("body", "second", "accent", "trim", "glow", "ink")
FLAT_ROLES = ("body", "second", "accent", "trim")  # surface colours; glow is light and ink is the anchor, neither counts
SHAPES = ("box", "wedge", "cone6", "ico1")
SHAPE_TRIS = {"box": 12, "wedge": 8, "cone6": 10, "ico1": 20}
BEVEL_TRIS = {1: 44, 2: 108}  # a bevelled box, measured in Blender 5.0.1 (the report)
MOVES = ("none", "wing", "tail", "ear", "halo", "sprout", "antenna", "crest", "float", "jaw")
STATUSES = ("concept", "board", "build", "review", "approved")
# rule 6, the ladder: blocks and height (studs) per tier, and how many flat colours
TIERS = {
    "Common": {"blocks": (5, 10), "height": (1.75, 2.5), "flat": (2, 3)},
    "Uncommon": {"blocks": (8, 15), "height": (2.0, 2.75), "flat": (2, 3)},
    "Rare": {"blocks": (15, 30), "height": (2.5, 3.25), "flat": (3, 4)},
    "Epic": {"blocks": (30, 60), "height": (3.25, 4.25), "flat": (3, 4)},
    "Legendary": {"blocks": (60, 100), "height": (4.75, 6.5), "flat": (3, 4)},
    "Cosmic": {"blocks": (100, 180), "height": (10.0, 20.0), "flat": (3, 4)},
    "Secret": {"blocks": (100, 180), "height": (10.0, 20.0), "flat": (3, 4)},
}
TIER_ORDER = tuple(TIERS)
# rule 3: the house eye, the same at every tier: a tall ink drop (k) with a shine bar on its outer top (w), a lit crescent along its
# bottom (g) and a sparkle (w) on the crescent's inner side. The right eye is the mirror image.
HOUSE_EYE_L = (".kk.", "kwkk", "kwkk", "kkkk", "kgwk", ".gg.")
HOUSE_EYE_R = tuple(row[::-1] for row in HOUSE_EYE_L)
REQUIRED_FRONT = ("id", "name", "world", "tier", "status", "height", "blocks", "tris", "palette", "roles", "hero", "artboard", "render", "glb")


class SpecError(ValueError):
    pass


# ------------------------------------------------------------------------------------------------ a small YAML subset
# Enough for frontmatter and the two blocks: block mappings and sequences by indentation, flow [lists] and {maps} on one line, quoted and plain
# scalars, numbers, booleans, null and # comments. No anchors, tags, multi-line strings or multi-line flow collections.

def _strip_comment(line):
    out, quote = [], None
    for i, ch in enumerate(line):
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#" and (i == 0 or line[i - 1] in " \t"):
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def _scalar(text):
    t = text.strip()
    if t in ("", "~", "null", "Null", "NULL"):
        return None
    if t in ("true", "True", "TRUE"):
        return True
    if t in ("false", "False", "FALSE"):
        return False
    if len(t) >= 2 and t[0] == t[-1] == '"':
        return json.loads(t)
    if len(t) >= 2 and t[0] == t[-1] == "'":
        return t[1:-1].replace("''", "'")
    if re.fullmatch(r"[-+]?\d+", t):
        return int(t)
    if re.fullmatch(r"[-+]?(\d+\.\d*|\.\d+|\d+)([eE][-+]?\d+)?", t):
        return float(t)
    return t


def _read_quoted(s, i):
    q = s[i]
    j = i + 1
    while j < len(s):
        if q == '"' and s[j] == "\\":
            j += 2
            continue
        if s[j] == q:
            if q == "'" and j + 1 < len(s) and s[j + 1] == "'":
                j += 2
                continue
            return s[i:j + 1], j + 1
        j += 1
    raise SpecError("unterminated string: %s" % s)


def _flow(s, i=0):
    """Parse one flow value starting at s[i]; return (value, next index)."""
    while i < len(s) and s[i] == " ":
        i += 1
    if i >= len(s):
        return None, i
    ch = s[i]
    if ch == "[":
        out, i = [], i + 1
        while True:
            while i < len(s) and s[i] == " ":
                i += 1
            if i < len(s) and s[i] == "]":
                return out, i + 1
            value, i = _flow(s, i)
            out.append(value)
            while i < len(s) and s[i] == " ":
                i += 1
            if i < len(s) and s[i] == ",":
                i += 1
            elif i < len(s) and s[i] == "]":
                return out, i + 1
            else:
                raise SpecError("bad flow list: %s" % s)
    if ch == "{":
        out, i = {}, i + 1
        while True:
            while i < len(s) and s[i] == " ":
                i += 1
            if i < len(s) and s[i] == "}":
                return out, i + 1
            if s[i] in "\"'":
                raw, i = _read_quoted(s, i)
                key = _scalar(raw)
            else:
                j = i
                while j < len(s) and s[j] != ":":
                    j += 1
                key = s[i:j].strip()
                i = j
            if i >= len(s) or s[i] != ":":
                raise SpecError("bad flow map (no colon): %s" % s)
            value, i = _flow(s, i + 1)
            out[key] = value
            while i < len(s) and s[i] == " ":
                i += 1
            if i < len(s) and s[i] == ",":
                i += 1
            elif i < len(s) and s[i] == "}":
                return out, i + 1
            else:
                raise SpecError("bad flow map: %s" % s)
    if ch in "\"'":
        raw, i = _read_quoted(s, i)
        return _scalar(raw), i
    j = i
    while j < len(s) and s[j] not in ",]}":
        j += 1
    return _scalar(s[i:j]), j


def _value(rest):
    rest = rest.strip()
    if rest[:1] in ("[", "{"):
        value, i = _flow(rest)
        if rest[i:].strip():
            raise SpecError("trailing text after flow value: %s" % rest)
        return value
    return _scalar(rest)


def _split_key(text):
    """'key: rest' -> (key, rest) or None; the key may be quoted."""
    if text[:1] in "\"'":
        raw, i = _read_quoted(text, 0)
        if text[i:i + 1] == ":" and (i + 1 == len(text) or text[i + 1] == " "):
            return _scalar(raw), text[i + 1:]
        return None
    m = re.match(r"([^\s:#][^:]*?)\s*:(\s|$)", text)
    if not m:
        return None
    return m.group(1), text[m.end() - (1 if m.group(2) else 0):]


def _block(lines, i, indent):
    """Parse the block starting at lines[i] (all at `indent`)."""
    if i >= len(lines):
        return None, i
    ind, text = lines[i]
    if text.startswith("- ") or text == "-":
        out = []
        while i < len(lines) and lines[i][0] == indent and (lines[i][1].startswith("- ") or lines[i][1] == "-"):
            rest = lines[i][1][2:] if lines[i][1] != "-" else ""
            i += 1
            kv = _split_key(rest) if rest[:1] not in ("[", "{", "\"", "'") else None
            if rest == "":
                if i < len(lines) and lines[i][0] > indent:
                    value, i = _block(lines, i, lines[i][0])
                else:
                    value = None
                out.append(value)
            elif kv is not None:
                # a mapping whose first key sits on the dash line; its other keys are indented to the key's column
                sub = [(indent + 2, rest)]
                while i < len(lines) and lines[i][0] > indent:
                    sub.append(lines[i])
                    i += 1
                value, _ = _block(sub, 0, indent + 2)
                out.append(value)
            else:
                out.append(_value(rest))
        return out, i
    out = {}
    while i < len(lines) and lines[i][0] == indent and not lines[i][1].startswith("- "):
        kv = _split_key(lines[i][1])
        if kv is None:
            raise SpecError("expected 'key: value', got: %s" % lines[i][1])
        key, rest = kv
        i += 1
        if rest.strip() == "":
            if i < len(lines) and (lines[i][0] > indent or (lines[i][0] == indent and lines[i][1].startswith("- "))):
                value, i = _block(lines, i, lines[i][0])
            else:
                value = None
        else:
            value = _value(rest)
        out[key] = value
    return out, i


def load_yaml(text):
    """Parse the YAML subset above into dicts, lists and scalars."""
    lines = []
    for raw in text.split("\n"):
        line = _strip_comment(raw.replace("\t", "    "))
        if line.strip() in ("", "---"):
            continue
        lines.append((len(line) - len(line.lstrip(" ")), line.strip()))
    if not lines:
        return None
    value, i = _block(lines, 0, lines[0][0])
    if i != len(lines):
        raise SpecError("could not parse past: %s" % lines[i][1])
    return value


# ------------------------------------------------------------------------------------------------ the note
FRONT = re.compile(r"\A---\n(.*?)\n---\n", re.S)
FENCE = re.compile(r"^```yaml[^\n]*\n(.*?)^```", re.S | re.M)


def read_note(text):
    """{'front': dict, 'parts': [raw part dicts], 'face': dict or None} from a creature note's text."""
    m = FRONT.match(text)
    if not m:
        raise SpecError("no frontmatter")
    front = load_yaml(m.group(1)) or {}
    parts, face = None, None
    for block in FENCE.finditer(text):
        data = load_yaml(block.group(1))
        if isinstance(data, dict) and "parts" in data:
            if parts is not None:
                raise SpecError("two parts blocks")
            parts = data["parts"] or []
        elif isinstance(data, dict) and "face" in data:
            face = data["face"]
    if parts is None:
        raise SpecError("no ```yaml block with a `parts` root key")
    return {"front": front, "parts": parts, "face": face}


def load(path):
    path = pathlib.Path(path)
    spec = read_note(path.read_text(encoding="utf-8"))
    spec["path"] = str(path)
    spec["parts"] = [normalise(p, i) for i, p in enumerate(spec["parts"])]
    return spec


def _vec(value, name, field, n=3):
    if not isinstance(value, list) or len(value) != n or not all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in value):
        raise SpecError("%s: %s must be a list of %d numbers, got %r" % (name, field, n, value))
    return [float(v) for v in value]


def normalise(raw, index=0):
    """One part with every field filled in (defaults: rot 0, bevel false, mirror none, shape box, moves none)."""
    if not isinstance(raw, dict):
        raise SpecError("part %d is not a mapping: %r" % (index, raw))
    name = str(raw.get("name") or "part%d" % index)
    known = {"name", "slot", "size", "at", "rot", "bevel", "mirror", "shape", "moves", "pivot"}
    extra = set(raw) - known
    if extra:
        raise SpecError("%s: unknown field(s) %s" % (name, ", ".join(sorted(extra))))
    part = {
        "name": name,
        "slot": raw.get("slot"),
        "size": _vec(raw.get("size"), name, "size"),
        "at": _vec(raw.get("at"), name, "at"),
        "rot": _vec(raw.get("rot", [0, 0, 0]), name, "rot"),
        "bevel": bool(raw.get("bevel", False)),
        "mirror": str(raw.get("mirror", "none")),
        "shape": str(raw.get("shape", "box")),
        "moves": str(raw.get("moves", "none")),
        "pivot": _vec(raw["pivot"], name, "pivot") if raw.get("pivot") is not None else None,
    }
    return part


def expand(parts):
    """Mirror every `mirror: x` part across x = 0. The copy's rot is (a, -b, -c), its pivot x is negated, and the pair is named <name>R (on +x,
    the creature's right) and <name>L. Unmirrored parts pass through. Every expanded part keeps `source`, the name in the note."""
    out = []
    for p in parts:
        if p["mirror"] != "x":
            out.append(dict(p, source=p["name"]))
            continue
        a = dict(p, source=p["name"])
        b = dict(p, source=p["name"])
        b["at"] = [-p["at"][0], p["at"][1], p["at"][2]]
        b["rot"] = [p["rot"][0], -p["rot"][1], -p["rot"][2]]
        if p["pivot"] is not None:
            b["pivot"] = [-p["pivot"][0], p["pivot"][1], p["pivot"][2]]
        right, left = (a, b) if p["at"][0] >= 0 else (b, a)
        right["name"], left["name"] = p["name"] + "R", p["name"] + "L"
        out += [right, left]
    return out


# ------------------------------------------------------------------------------------------------ geometry (shared by the sheet and the build)
PHI = (1 + 5 ** 0.5) / 2


def _unit_shapes():
    box_v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    idx = {v: i for i, v in enumerate(box_v)}
    q = lambda *vs: [idx[v] for v in vs]  # noqa: E731
    h = 0.5
    box_f = [
        q((-h, -h, -h), (-h, -h, h), (-h, h, h), (-h, h, -h)),   # -x
        q((h, -h, -h), (h, h, -h), (h, h, h), (h, -h, h)),       # +x
        q((-h, -h, -h), (h, -h, -h), (h, -h, h), (-h, -h, h)),   # -y
        q((-h, h, -h), (-h, h, h), (h, h, h), (h, h, -h)),       # +y
        q((-h, -h, -h), (-h, h, -h), (h, h, -h), (h, -h, -h)),   # -z (front)
        q((-h, -h, h), (h, -h, h), (h, h, h), (-h, h, h)),       # +z (back)
    ]
    # wedge: Roblox's WedgePart: full height at the back (+z), the slope faces front and up
    wedge_v = [(-h, -h, -h), (h, -h, -h), (h, -h, h), (-h, -h, h), (-h, h, h), (h, h, h)]
    wedge_f = [[0, 1, 2, 3], [2, 5, 4, 3], [4, 5, 1, 0], [0, 3, 4], [1, 5, 2]]
    # cone6: six sides, base on -y filling the box in x and z, apex at +y
    cone_v = [(0.5 * math.cos(math.radians(60 * k)), -h, 0.5 * math.sin(math.radians(60 * k)) / math.sin(math.radians(60))) for k in range(6)]
    cone_v.append((0.0, h, 0.0))
    cone_f = [[k, 6, (k + 1) % 6] for k in range(6)] + [[0, 1, 2, 3, 4, 5]]
    # ico1: the icosahedron (Blender's ico sphere at subdivision 1), scaled to fill the box
    raw = []
    for a in (-1, 1):
        for b in (-1, 1):
            raw += [(0, a, b * PHI), (a, b * PHI, 0), (b * PHI, 0, a)]
    ico_v = [tuple(c / (2 * PHI) for c in v) for v in raw]
    ico_f = []
    n = len(ico_v)
    edge = min(math.dist(ico_v[i], ico_v[j]) for i in range(n) for j in range(i + 1, n))
    near = lambda i, j: abs(math.dist(ico_v[i], ico_v[j]) - edge) < 1e-6  # noqa: E731
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                if near(i, j) and near(j, k) and near(i, k):
                    a, b, c = ico_v[i], ico_v[j], ico_v[k]
                    u = [b[t] - a[t] for t in range(3)]
                    v = [c[t] - a[t] for t in range(3)]
                    nrm = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
                    ctr = [(a[t] + b[t] + c[t]) for t in range(3)]
                    ico_f.append([i, j, k] if sum(nrm[t] * ctr[t] for t in range(3)) > 0 else [i, k, j])
    return {"box": (box_v, box_f), "wedge": (wedge_v, wedge_f), "cone6": (cone_v, cone_f), "ico1": (ico_v, ico_f)}


UNIT = _unit_shapes()


def rot_matrix(rot):
    """Euler XYZ in degrees -> 3x3 rows (R = Rz . Ry . Rx, as Blender's XYZ mode)."""
    a, b, c = (math.radians(v) for v in rot)
    ca, sa, cb, sb, cc, sc = math.cos(a), math.sin(a), math.cos(b), math.sin(b), math.cos(c), math.sin(c)
    rx = ((1, 0, 0), (0, ca, -sa), (0, sa, ca))
    ry = ((cb, 0, sb), (0, 1, 0), (-sb, 0, cb))
    rz = ((cc, -sc, 0), (sc, cc, 0), (0, 0, 1))
    mul = lambda m, n: tuple(tuple(sum(m[i][k] * n[k][j] for k in range(3)) for j in range(3)) for i in range(3))  # noqa: E731
    return mul(rz, mul(ry, rx))


def part_mesh(part):
    """(vertices, faces) of one expanded part in creature space (studs), from the unit shape scaled, rotated and moved."""
    verts, faces = UNIT[part["shape"]]
    m = rot_matrix(part["rot"])
    out = []
    for v in verts:
        s = [v[i] * part["size"][i] for i in range(3)]
        r = [sum(m[i][k] * s[k] for k in range(3)) for i in range(3)]
        out.append(tuple(r[i] + part["at"][i] for i in range(3)))
    return out, [list(f) for f in faces]


def bounds(parts):
    lo, hi = [1e9] * 3, [-1e9] * 3
    for p in parts:
        for v in part_mesh(p)[0]:
            for i in range(3):
                lo[i], hi[i] = min(lo[i], v[i]), max(hi[i], v[i])
    return lo, hi


def part_tris(part, segments):
    if part["bevel"]:
        return BEVEL_TRIS.get(segments, 12)
    return SHAPE_TRIS[part["shape"]]


def counts(spec):
    """{'blocks', 'tris', 'height', 'masses', 'movers'} of a loaded spec (tris as built, before Blender: the build measures the real number)."""
    parts = expand(spec["parts"])
    seg = int(spec["front"].get("bevel_segments") or 2)
    lo, hi = bounds(parts)
    return {
        "blocks": len(parts),
        "tris": sum(part_tris(p, seg) for p in parts),
        "height": round(hi[1], 3),
        "bottom": round(lo[1], 3),
        "width": round(hi[0] - lo[0], 3),
        "depth": round(hi[2] - lo[2], 3),
        "masses": sum(1 for p in parts if p["bevel"]),
        "movers": len(movers(parts)),
    }


def movers(parts):
    """The moving objects: parts grouped by (moves, pivot). {key: [parts]}; a key is '<moves>' or '<moves>L/R' for a mirrored pair."""
    groups = {}
    for p in parts:
        if p["moves"] == "none":
            continue
        piv = tuple(p["pivot"] or p["at"])
        side = "R" if piv[0] > 1e-9 else ("L" if piv[0] < -1e-9 else "")
        groups.setdefault((p["moves"], piv, side), []).append(p)
    out = {}
    for (kind, piv, side), members in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][2], kv[0][1])):
        key = kind + side
        n = 2
        while key in out:
            key = "%s%s%d" % (kind, side, n)
            n += 1
        out[key] = {"pivot": list(piv), "parts": members}
    return out


# ------------------------------------------------------------------------------------------------ colour
def hex_rgb(h):
    h = str(h).strip().lstrip("#")
    if not re.fullmatch(r"[0-9A-Fa-f]{6}", h):
        raise SpecError("not a hex colour: %r" % h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lstar(h):
    """CIE L* (0 to 100) of an sRGB hex: the greyscale value the palette is checked on."""
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in hex_rgb(h))
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return 116 * (y ** (1 / 3) if y > 216 / 24389 else (24389 / 27 * y + 16) / 116) - 16


def palette(spec):
    """{role: '#RRGGBB'} from the frontmatter's parallel `palette` and `roles` lists."""
    front = spec["front"]
    hexes, roles = front.get("palette") or [], front.get("roles") or []
    if len(hexes) != len(roles):
        raise SpecError("palette and roles differ in length (%d, %d)" % (len(hexes), len(roles)))
    return {r: "#" + str(h).strip().lstrip("#").upper() for r, h in zip(roles, hexes)}


def slot_hex(spec, slot):
    return palette(spec)[SLOT_ROLE[slot]]


def face_colour(spec, char):
    """The hex of one face-grid character: its legend entry is a palette role or a literal hex."""
    legend = (spec.get("face") or {}).get("legend") or {}
    value = str(legend[char])
    pal = palette(spec)
    return pal[value] if value in pal else "#" + value.lstrip("#").upper()


def face_host(spec):
    face = spec.get("face")
    if not face:
        return None
    for p in spec["parts"]:
        if p["name"] == face.get("host"):
            return p
    return None


# ------------------------------------------------------------------------------------------------ validation
def _on(value, step):
    return abs(value / step - round(value / step)) < 1e-6


def _tilt(angle):
    r = ((angle + 45.0) % 90.0) - 45.0
    return abs(r)


def validate(spec):
    """(errors, warnings): lists of strings, each naming the Blocky-Style rule it breaks."""
    errors, warnings = [], []
    front, parts_in = spec["front"], spec["parts"]
    err = errors.append
    for key in REQUIRED_FRONT:
        if key not in front:
            err("frontmatter: missing `%s`" % key)
    tier = front.get("tier")
    if tier not in TIERS:
        err("frontmatter: tier %r is not one of %s" % (tier, ", ".join(TIERS)))
        tier = None
    if front.get("status") not in STATUSES:
        err("frontmatter: status %r is not one of %s" % (front.get("status"), ", ".join(STATUSES)))
    names = [p["name"] for p in parts_in]
    for n in sorted({n for n in names if names.count(n) > 1}):
        err("parts: the name %s is used twice" % n)
    try:
        pal = palette(spec)
    except SpecError as exc:
        err("rule 4: %s" % exc)
        pal = {}
    seg = front.get("bevel_segments")
    width = front.get("bevel_width")
    if seg not in (1, 2):
        err("rule 1: bevel_segments must be 1 or 2, got %r" % seg)
    for p in parts_in:
        n = p["name"]
        if p["slot"] not in SLOTS:
            err("%s: slot %r is not one of %s" % (n, p["slot"], ", ".join(SLOTS)))
        elif pal and SLOT_ROLE[p["slot"]] not in pal:
            err("rule 4: %s: slot %s needs the palette role `%s`" % (n, p["slot"], SLOT_ROLE[p["slot"]]))
        if p["shape"] not in SHAPES:
            err("%s: shape %r is not one of %s" % (n, p["shape"], ", ".join(SHAPES)))
        if p["mirror"] not in ("x", "none"):
            err("%s: mirror %r is not x or none" % (n, p["mirror"]))
        if p["mirror"] == "x" and abs(p["at"][0]) < 1e-9:
            err("%s: mirrored across x but centred on x = 0" % n)
        if p["moves"] not in MOVES:
            err("%s: moves %r is not one of %s" % (n, p["moves"], ", ".join(MOVES)))
        if p["moves"] != "none" and p["pivot"] is None:
            err("rule 8: %s moves (%s) but has no pivot" % (n, p["moves"]))
        if p["moves"] == "none" and p["pivot"] is not None:
            err("%s: a pivot on a part that does not move" % n)
        if min(p["size"]) <= 0:
            err("%s: every size must be positive" % n)
        tilted = False
        for i, angle in enumerate(p["rot"]):
            t = _tilt(angle)
            if t > 1e-6:
                tilted = True
                if not TILT_MIN - 1e-6 <= t <= TILT_MAX + 1e-6:
                    err("rule 1: %s: rot %s %g is a tilt of %g degrees; a tilt is %g to %g off a quarter turn" % (n, "xyz"[i], angle, t, TILT_MIN, TILT_MAX))
        step = GRID if p["bevel"] else HALF
        for i, axis in enumerate("xyz"):
            if not _on(p["size"][i], step):
                err("rule 2: %s: size %s = %g is off the %g grid" % (n, axis, p["size"][i], step))
            if tilted:
                # a tilted appendage's faces cannot sit on the grid; its centre sits on the sixteenth grid so it can meet its root
                if not _on(p["at"][i], TILT_SNAP):
                    err("rule 2: %s: a tilted part's centre %s = %g is off the %g grid" % (n, axis, p["at"][i], TILT_SNAP))
                continue
            for face_pos in (p["at"][i] - p["size"][i] / 2, p["at"][i] + p["size"][i] / 2):
                if not _on(face_pos, HALF):
                    err("rule 2: %s: its %s face at %g is off the %g half grid" % (n, axis, face_pos, HALF))
                    break
        if p["bevel"]:
            if p["shape"] != "box":
                err("rule 1: %s: only a box mass is bevelled" % n)
            if any(abs(a) > 1e-9 for a in p["rot"]):
                err("rule 1: %s: a bevelled mass stays axis-aligned (no rot)" % n)
            if p["moves"] != "none":
                err("rule 1: %s: a bevelled mass does not move" % n)
    parts = expand(parts_in) if not any(e.startswith("parts") for e in errors) else []
    try:
        c = counts(spec)
    except (SpecError, KeyError):
        return errors, warnings
    masses = [p for p in parts if p["bevel"]]
    if not MASSES[0] <= len(masses) <= MASSES[1]:
        err("rule 1: %d bevelled masses; a creature has %d to %d" % (len(masses), MASSES[0], MASSES[1]))
    if masses and isinstance(width, (int, float)):
        smallest = min(min(p["size"]) for p in masses)
        share = width / smallest
        if not BEVEL_SHARE[0] - 1e-9 <= share <= BEVEL_SHARE[1] + 1e-9:
            err("rule 1: bevel_width %g is %.1f%% of the smallest mass side %g; it must be %d to %d%%" % (
                width, share * 100, smallest, BEVEL_SHARE[0] * 100, BEVEL_SHARE[1] * 100))
    elif masses:
        err("rule 1: bevel_width is missing")
    # heights and proportions
    height = front.get("height")
    if not isinstance(height, (int, float)) or abs(height - c["height"]) > 0.011:
        err("rule 2: frontmatter height %r does not match the tallest point %.2f" % (height, c["height"]))
    if abs(c["bottom"]) > 1e-6:
        err("rule 2: the lowest point is at y = %.3f; the feet stand on y = 0" % c["bottom"])
    host = face_host(spec)
    if host is not None and c["height"] > 0:
        share = host["size"][1] / c["height"]
        if not HEAD_SHARE[0] - 1e-6 <= share <= HEAD_SHARE[1] + 1e-6:
            err("rule 2: the head (%s) is %.0f%% of the height; it must be %d to %d%%" % (host["name"], share * 100, HEAD_SHARE[0] * 100, HEAD_SHARE[1] * 100))
        others = [p for p in masses if p["source"] != host["name"]]
        if others and host["size"][0] + 1e-9 < max(p["size"][0] for p in others):
            err("rule 2: the head (%s) is narrower than a body mass" % host["name"])
    if masses and c["height"] > 0:
        gap = min(p["at"][1] - p["size"][1] / 2 for p in masses)
        share = gap / c["height"]
        if not LEG_SHARE[0] - 1e-6 <= share <= LEG_SHARE[1] + 1e-6:
            err("rule 2: the legs (the gap under the lowest mass, %.2f) are %.0f%% of the height; they must be %d to %d%%" % (
                gap, share * 100, LEG_SHARE[0] * 100, LEG_SHARE[1] * 100))
    # the ladder
    if tier:
        band = TIERS[tier]
        lo_b, hi_b = band["blocks"]
        if not lo_b <= c["blocks"] <= hi_b:
            err("rule 6: %d blocks; a %s has %d to %d" % (c["blocks"], tier, lo_b, hi_b))
        lo_h, hi_h = band["height"]
        if not lo_h - 1e-6 <= c["height"] <= hi_h + 1e-6:
            err("rule 6: %.2f studs tall; a %s stands %g to %g" % (c["height"], tier, lo_h, hi_h))
        flats = [r for r in FLAT_ROLES if r in pal]
        if pal and not band["flat"][0] <= len(flats) <= band["flat"][1]:
            err("rule 4: %d flat colours (%s); a %s has %d to %d plus the ink" % (len(flats), ", ".join(flats), tier, band["flat"][0], band["flat"][1]))
        if tier in ("Common", "Uncommon") and any(p["slot"] == "Glow" for p in parts):
            err("rule 7: a %s has no glow region" % tier)
        if TIER_ORDER.index(tier) >= TIER_ORDER.index("Epic"):
            regions = {p["source"] for p in parts if p["slot"] == "Glow"}
            if not regions:
                err("rule 7: an %s has glow regions" % tier)
    if c["tris"] > TRI_CAP:
        err("rule 1: %d triangles; the cap is %d" % (c["tris"], TRI_CAP))
    if c["movers"] > MOVERS_MAX:
        err("rule 8: %d moving objects; at most %d" % (c["movers"], MOVERS_MAX))
    # palette
    if pal:
        if "ink" not in pal:
            err("rule 4: the palette has no `ink`")
        elif lstar(pal["ink"]) > INK_LSTAR_MAX:
            err("rule 4: the ink %s has L* %.0f; near-black is under %g" % (pal["ink"], lstar(pal["ink"]), INK_LSTAR_MAX))
        for r in pal:
            if r not in ROLES:
                err("rule 4: unknown palette role `%s`" % r)
        for (a, b), gap in LSTAR_GAP.items():
            if a in pal and b in pal and abs(lstar(pal[a]) - lstar(pal[b])) < gap:
                err("rule 4: %s and %s are %.0f apart in greyscale (L*); they need %g" % (a, b, abs(lstar(pal[a]) - lstar(pal[b])), gap))
        if pal and str(front.get("palette", [""])[0]).upper().lstrip("#") != pal.get("body", "").lstrip("#"):
            warnings.append("rule 4: the first palette entry is not the body colour (the roster card shows the first)")
    # hero
    hero = front.get("hero")
    if hero and hero not in names:
        err("rule 1: hero %r is not a part name" % hero)
    errors += validate_face(spec, host)
    return errors, warnings


def validate_face(spec, host):
    errors = []
    face = spec.get("face")
    if not face:
        return ["rule 3: no ```yaml block with a `face` root key"]
    if host is None:
        return ["rule 3: face.host %r is not a part name" % face.get("host")]
    if host["mirror"] != "none" or host["shape"] != "box":
        errors.append("rule 3: the face host %s must be one unmirrored box" % host["name"])
    if any(abs(a) > 1e-9 for a in host["rot"]):
        errors.append("rule 3: the face host %s does not rotate" % host["name"])
    rows = face.get("rows") or []
    legend = face.get("legend") or {}
    if not rows:
        return errors + ["rule 3: the face has no rows"]
    cols = len(rows[0])
    if cols not in FACE_COLS or any(len(r) != cols for r in rows):
        errors.append("rule 3: face rows must all be 16 or 32 cells wide (got %s)" % sorted({len(r) for r in rows}))
        return errors
    w, h = host["size"][0], host["size"][1]
    want = cols * h / w
    if abs(want - round(want)) > 1e-6 or len(rows) != round(want):
        errors.append("rule 3: the head front is %g x %g studs, so %d columns need %.2f rows for square cells; the face has %d" % (w, h, cols, want, len(rows)))
    used = {ch for r in rows for ch in r}
    missing = sorted(used - set(legend))
    if missing:
        errors.append("rule 3: face characters with no legend entry: %s" % " ".join(missing))
    pal_roles = set((spec["front"].get("roles") or []))
    for ch, value in legend.items():
        v = str(value)
        if v not in pal_roles and not re.fullmatch(r"#?[0-9A-Fa-f]{6}", v):
            errors.append("rule 3: legend %r -> %r is neither a palette role nor a hex" % (ch, v))
    body_role = SLOT_ROLE.get(host["slot"])
    border = rows[0] + rows[-1] + "".join(r[0] + r[-1] for r in rows)
    bad = {ch for ch in border if str(legend.get(ch)) != body_role}
    if bad:
        errors.append("rule 3: the face border must be the head's own colour (%s); found %s" % (body_role, " ".join(sorted(bad))))
    for need in ("k", "w", "g"):
        if need not in legend:
            errors.append("rule 3: the legend needs `%s` (the house eye)" % need)
    if str(legend.get("k")) != "ink":
        errors.append("rule 3: `k` is the ink")
    if str(legend.get("g")) not in ("glow", "accent"):
        errors.append("rule 3: `g`, the eye's lit crescent, is the glow (or the accent on a tier with no glow)")
    found = {"L": find_stamp(rows, HOUSE_EYE_L), "R": find_stamp(rows, HOUSE_EYE_R)}
    if not found["L"] or not found["R"]:
        errors.append("rule 3: the house eye is not on the face (left %s, right %s)" % (bool(found["L"]), bool(found["R"])))
    else:
        (lr, lc), (rr, rc) = found["L"][0], found["R"][-1]
        if lr != rr or lc >= rc:
            errors.append("rule 3: the two eyes are not level, left then right")
        elif lc + 4 + rc != cols:
            errors.append("rule 3: the eyes are not placed symmetrically")
        if (lr + len(HOUSE_EYE_L) / 2) / len(rows) < 0.45:
            errors.append("rule 3: the eyes sit in the upper half of the face; they belong in the lower half")
    return errors


def find_stamp(rows, stamp):
    """Every (row, col) where `stamp` (a list of strings, '.' = must be the face's body cell too) matches the grid exactly."""
    hits = []
    sh, sw = len(stamp), len(stamp[0])
    for r in range(len(rows) - sh + 1):
        for c in range(len(rows[0]) - sw + 1):
            if all(rows[r + i][c:c + sw] == stamp[i] for i in range(sh)):
                hits.append((r, c))
    return hits


# ------------------------------------------------------------------------------------------------ write back
def _yaml_scalar(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return ("%g" % value) if isinstance(value, float) else str(value)
    if isinstance(value, list):
        return "[" + ", ".join(_yaml_scalar(v) for v in value) + "]"
    text = str(value)
    if text == "" or re.search(r"[:#\[\]{},&*!|>'\"%@`]", text) or text != text.strip():
        return json.dumps(text)
    return text


def set_front(text, updates):
    """Return `text` with frontmatter keys set to new values (existing lines replaced in place, new keys appended at the end)."""
    m = FRONT.match(text)
    if not m:
        raise SpecError("no frontmatter")
    lines = m.group(1).split("\n")
    for key, value in updates.items():
        line = "%s: %s" % (key, _yaml_scalar(value))
        for i, old in enumerate(lines):
            if re.match(r"%s\s*:" % re.escape(key), old):
                j = i + 1
                while j < len(lines) and (lines[j].startswith(" ") or lines[j].startswith("-")):
                    j += 1  # a block value under the key goes with it
                lines[i:j] = [line]
                break
        else:
            lines.append(line)
    return "---\n" + "\n".join(lines) + "\n---\n" + text[m.end():]


def write_counts(path, spec=None):
    path = pathlib.Path(path)
    spec = spec or load(path)
    c = counts(spec)
    text = set_front(path.read_text(encoding="utf-8"), {"blocks": c["blocks"], "tris": c["tris"]})
    path.write_text(text, encoding="utf-8")
    return c


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    bad = 0
    for p in paths:
        try:
            spec = load(p)
            errors, warnings = validate(spec)
        except SpecError as exc:
            print("%s: ERROR %s" % (p, exc))
            bad += 1
            continue
        c = counts(spec)
        print("%-12s %-9s blocks %3d  tris %4d (estimate)  height %.2f  masses %d  movers %d" % (
            spec["front"].get("id"), spec["front"].get("tier"), c["blocks"], c["tris"], c["height"], c["masses"], c["movers"]))
        for e in errors:
            print("  error: " + e)
        for w in warnings:
            print("  warning: " + w)
        if errors:
            bad += 1
        elif "--write" in argv:
            write_counts(p, spec)
            print("  wrote blocks and tris")
        if "--json" in argv:
            print(json.dumps(expand(spec["parts"]), indent=1))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
