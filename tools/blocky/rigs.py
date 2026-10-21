#!/usr/bin/env python3
"""Generate src/shared/data/Rigs.luau from the spec notes that carry a `rig` block (Decision B46, Blocky-Style rule 8).

Every note on the B46 format (an `eyes` block and a `rig` block; tools/blocky/spec.py validates both) becomes one row, keyed by species id:
its built height, every moving object with its pivot and clips (a mirrored pair expanded, the left twin mirrored), the clips of the whole body
(`root`), the face plate's flipbook (frame size and layout from tools/blocky/eyes.py, the image id 0 until uploaded, the blink, glint and cycle
timings) and the flourish. Pivots are in the model's own space: studs from the bottom centre of the alien's bounds, where Models.Clone puts the
clone's pivot. The game plays the rows with World.RigAnimator; the math is Shared/RigMath, and `pose()` below is the same math in Python
for the Blender idle preview (tools/blender/blocky_build.py --idle).

  python3 -I tools/blocky/rigs.py                 # write src/shared/data/Rigs.luau from every note in docs/vault/07-alien-game/Creatures
  python3 -I tools/blocky/rigs.py --check         # exit 1 when the file is out of date (tools/tests/test_blocky_rigs.py runs it)

An uploaded flipbook keeps its id: an image id already in Rigs.luau for a species is carried over when the file is written again.
"""
from __future__ import annotations

import math
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
import eyes as E  # noqa: E402
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
OUT = ROOT / "src/shared/data/Rigs.luau"
# phone budgets (Types.RigBudget): written into the data file, read by World.RigAnimator
BUDGET = {"MaxAnimated": 12, "PhoneMaxAnimated": 6, "Distance": 80, "RecheckSeconds": 0.5, "FallbackHalf": 0.55, "FallbackClosed": 0.15}
FACE_PART = "FacePlate"


def _num(v):
    v = round(float(v), 4)
    if v == int(v):
        return str(int(v))
    return ("%.4f" % v).rstrip("0").rstrip(".")


def _vec(v):
    return "{ %s }" % ", ".join(_num(x) for x in v)


def _ints(v):
    return "{ %s }" % ", ".join(str(i) for i in v) if v else "{}"


def _clip(c):
    return '{ kind = "%s", amp = %s, period = %s, phase = %s, axis = "%s" }' % (c["kind"], _num(c["amp"]), _num(c["period"]), _num(c["phase"]), c["axis"])


def _move(m):
    return '{ part = "%s", kind = "%s", amp = %s, axis = "%s", at = %s, length = %s }' % (
        m["part"], m["kind"], _num(m["amp"]), m["axis"], _num(m["at"]), _num(m["for"]))


def centre_of(spec):
    lo, hi = S.bounds(S.expand(spec["parts"]))
    return [(lo[0] + hi[0]) / 2, 0.0, (lo[2] + hi[2]) / 2]


def row(spec, images=None):
    """The data of one species (a dict the writer and the Blender preview share)."""
    front = spec["front"]
    sid, tier = front["id"], front["tier"]
    r = S.rig(spec)
    targets = S.rig_targets(spec)
    c = centre_of(spec)
    parts = []
    for key in sorted(k for k in r["clips"] if k not in S.RESERVED_MOVES):
        piv = targets[key]["pivot"]
        parts.append({"name": key, "pivot": [piv[0] - c[0], piv[1], piv[2] - c[2]], "clips": r["clips"][key]})
    eyes = spec["eyes"]
    key = eyes["key"]
    lay = S.plate_layout(spec)
    names = E.frame_names(key)
    cols, _ = E.sheet_layout(len(names))
    blink = next(cl for cl in r["clips"]["face"] if cl["kind"] == "blink")
    floor = E.DESIGNS[key]["tier"]
    face = {
        "part": FACE_PART, "image": (images or {}).get(sid, 0), "frameWidth": lay["w"], "frameHeight": lay["h"], "columns": cols,
        "frames": len(names), "open": names.index("open"), "half": names.index("half"), "closed": names.index("closed"),
        "glint": [i for i, n in enumerate(names) if n.startswith("glint")], "cycle": [i for i, n in enumerate(names) if n.startswith("cycle")],
        "blinkEvery": blink["period"], "blinkLength": E.BLINK_SECONDS,
        "glintEvery": E.GLINT_EVERY.get(tier, 0) if E.has_glint(key) else 0, "glintLength": E.GLINT_SECONDS if E.has_glint(key) else 0,
        "cycleFps": E.CYCLE_FPS.get(floor, 0) if E.cycle_count(key) else 0,
    }
    return {"id": sid, "tier": tier, "height": S.counts(spec)["height"], "parts": parts, "root": r["clips"].get("root", []), "face": face,
            "flourish": r["flourish"], "centre": c}


def b46_notes(folder=CREATURES):
    out = []
    for path in sorted(pathlib.Path(folder).glob("*.md")):
        spec = S.load(path)
        if S.is_b46(spec) and spec.get("rig"):
            out.append(spec)
    return out


def existing_images(path=OUT):
    """Image ids already in the data file (an uploaded flipbook), so a regeneration keeps them."""
    if not pathlib.Path(path).exists():
        return {}
    text = pathlib.Path(path).read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r"\n\t(\w+) = \{.*?part = \"%s\", image = (\d+)" % FACE_PART, text, re.S):
        out[m.group(1)] = int(m.group(2))
    return out


def render(rows):
    lines = [
        "--!strict",
        "-- GENERATED by tools/blocky/rigs.py from the spec notes in docs/vault/07-alien-game/Creatures (the `rig` and `eyes` blocks); do not edit",
        "-- by hand: change the note and run `python3 -I tools/blocky/rigs.py`. One row per species id on the B46 format (Decision B46): its built",
        "-- height, every moving part (named as the Blender object, its pivot in studs from the bottom centre of its bounds, its looping clips),",
        "-- the clips of the whole body (`root`), the face plate's flipbook (image 0 until uploaded; frames left to right, `columns` a row) and the",
        "-- flourish (Rare and up). Drawn by the client's World.RigAnimator with Shared/RigMath; the server never reads it. Budget: the phone caps.",
        "-- A species without a row (the old blockouts) is simply not animated by the rig.",
        "local Types = require(script.Parent.Parent.types.Types)",
        "",
        "local budget: Types.RigBudget = {",
    ]
    for k, v in BUDGET.items():
        lines.append("\t%s = %s," % (k, _num(v)))
    lines += ["}", "", "local species: { [string]: Types.RigRow } = {"]
    for r in rows:
        lines.append("\t%s = {" % r["id"])
        lines.append("\t\theight = %s," % _num(r["height"]))
        lines.append("\t\tparts = {")
        for p in r["parts"]:
            lines.append('\t\t\t{ name = "%s", pivot = %s, clips = { %s } },' % (p["name"], _vec(p["pivot"]), ", ".join(_clip(c) for c in p["clips"])))
        lines.append("\t\t},")
        lines.append("\t\troot = { %s }," % ", ".join(_clip(c) for c in r["root"]) if r["root"] else "\t\troot = {},")
        f = r["face"]
        lines.append("\t\tface = {")
        lines.append('\t\t\tpart = "%s", image = %d, frameWidth = %d, frameHeight = %d, columns = %d, frames = %d,' % (
            f["part"], f["image"], f["frameWidth"], f["frameHeight"], f["columns"], f["frames"]))
        lines.append("\t\t\topen = %d, half = %d, closed = %d, glint = %s, cycle = %s," % (
            f["open"], f["half"], f["closed"], _ints(f["glint"]), _ints(f["cycle"])))
        lines.append("\t\t\tblinkEvery = %s, blinkLength = %s, glintEvery = %s, glintLength = %s, cycleFps = %s," % (
            _num(f["blinkEvery"]), _num(f["blinkLength"]), _num(f["glintEvery"]), _num(f["glintLength"]), _num(f["cycleFps"])))
        lines.append("\t\t},")
        fl = r["flourish"]
        if fl:
            lines.append("\t\tflourish = {")
            lines.append("\t\t\tevery = %s, length = %s," % (_num(fl["every"]), _num(fl["length"])))
            lines.append("\t\t\tmoves = {")
            for m in fl["moves"]:
                lines.append("\t\t\t\t%s," % _move(m))
            lines.append("\t\t\t},")
            lines.append("\t\t},")
        lines.append("\t},")
    lines += ["}", "", "return {", "\tSpecies = species,", "\tBudget = budget,", "}", ""]
    return "\n".join(lines)


def generate(folder=CREATURES, out=OUT):
    images = existing_images(out)
    rows = []
    for spec in b46_notes(folder):
        errors, _ = S.validate(spec)
        if errors:
            raise S.SpecError("%s: %d spec errors; fix the note first:\n  %s" % (spec["path"], len(errors), "\n  ".join(errors)))
        rows.append(row(spec, images))
    return render(rows), rows


# ------------------------------------------------------------------------------------------------ the same math as Shared/RigMath, for the preview
TAU = math.pi * 2


def new_pose():
    return {"p": [0.0, 0.0, 0.0], "r": [0.0, 0.0, 0.0], "s": [1.0, 1.0, 1.0]}


def _ax(axis):
    return "xyz".index(axis)


def _stretch(pose, axis, share):
    i = _ax(axis)
    for k in range(3):
        pose["s"][k] *= (1 + share) if k == i else (1 - share / 2)


def accumulate(pose, clip, now, offset):
    if clip["kind"] == "blink" or clip["period"] <= 0:
        return
    u = now / clip["period"] + clip["phase"] + offset
    kind, amp, i = clip["kind"], clip["amp"], _ax(clip["axis"])
    if kind == "bob":
        pose["p"][i] += amp * math.sin(TAU * u)
    elif kind == "sway":
        pose["r"][i] += math.radians(amp) * math.sin(TAU * u)
    elif kind == "flap":
        pose["r"][i] += math.radians(amp) * (1 - math.cos(TAU * u)) / 2
    elif kind == "spin":
        pose["r"][i] += math.radians(amp) * (u % 1)
    elif kind == "wag":
        pose["r"][i] += math.radians(amp) * math.sin(2 * TAU * u) * max(0.0, math.sin(TAU * u))
    elif kind == "squash":
        _stretch(pose, clip["axis"], amp * math.sin(TAU * u))
    elif kind == "pulse":
        for k in range(3):
            pose["s"][k] *= 1 + amp * (0.5 + 0.5 * math.sin(TAU * u))
    elif kind == "orbit":
        a, b = amp * math.cos(TAU * u), amp * math.sin(TAU * u)
        j, k = [n for n in range(3) if n != i]
        pose["p"][j] += a
        pose["p"][k] += b


def accumulate_move(pose, move, elapsed):
    if move["for"] <= 0 or elapsed < move["at"] or elapsed > move["at"] + move["for"]:
        return
    s = (elapsed - move["at"]) / move["for"]
    kind, amp, i = move["kind"], move["amp"], _ax(move["axis"])
    if kind == "hop":
        pose["p"][i] += amp * math.sin(math.pi * s)
    elif kind == "turn":
        pose["r"][i] += math.radians(amp) * s * s * (3 - 2 * s)
    elif kind == "flare":
        pose["r"][i] += math.radians(amp) * math.sin(math.pi * s)
    elif kind == "swish":
        pose["r"][i] += math.radians(amp) * math.sin(2 * TAU * s) * (1 - s)
    elif kind == "pop":
        for k in range(3):
            pose["s"][k] *= 1 + amp * math.sin(math.pi * s)
    elif kind == "squash":
        _stretch(pose, move["axis"], amp * math.sin(TAU * s))


def face_frame(face, now, offset):
    if face["blinkEvery"] > 0:
        into = (now + offset * face["blinkEvery"]) % face["blinkEvery"]
        if into < face["blinkLength"]:
            third = face["blinkLength"] / 3
            return face["half"] if (into < third or into >= 2 * third) else face["closed"]
    if face["glint"] and face["glintEvery"] > 0:
        into = (now + (offset + 0.5) * face["glintEvery"]) % face["glintEvery"]
        if into < face["glintLength"]:
            third = face["glintLength"] / 3
            return face["glint"][min(1, len(face["glint"]) - 1)] if third <= into < 2 * third else face["glint"][0]
    if face["cycle"] and face["cycleFps"] > 0:
        return face["cycle"][int(math.floor((now + offset * len(face["cycle"])) * face["cycleFps"])) % len(face["cycle"])]
    return face["open"]


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    text, rows = generate()
    if "--check" in argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("%s is out of date: run python3 -I tools/blocky/rigs.py" % OUT.relative_to(ROOT))
            return 1
        print("rigs: up to date (%d species)" % len(rows))
        return 0
    OUT.write_text(text, encoding="utf-8")
    for r in rows:
        print("%-12s %-9s %d parts, %d root clips, face %dx%d x %d frames, flourish %s" % (
            r["id"], r["tier"], len(r["parts"]), len(r["root"]), r["face"]["frameWidth"], r["face"]["frameHeight"], r["face"]["frames"],
            ("%d moves" % len(r["flourish"]["moves"])) if r["flourish"] else "none"))
    print("wrote %s" % OUT.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
