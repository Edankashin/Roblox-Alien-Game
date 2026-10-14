#!/usr/bin/env python3
"""Check the species-name candidates against the second-pass rules.

  python3 -I tools/names_check.py [--section "Second pass"]

Reads the tables under the "## Second pass ..." heading of docs/vault/01-game-design/Species-Names.md
(Id | Now | A | B | C | My pick | Shape) and the species rows of src/shared/data/Species.luau, then checks the
A column, the B column, the C column and the "My pick" mix, each as a whole roster. Prints "names: clean" and
exits 0, or one line per problem and exits 1. Re-run it after any edit to the tables or to a pick.

The Shape cell is the shape number 1 to 7 (one number for A, B and C, or "a/b/c" when they differ):
1 monosyllable or near, 2 reduplication, 3 diminutive suffix (-let -kin -ling -bit -et), 4 compound of
animal and feature, 5 hard-consonant ending (-k -x -nch -ng), 6 nonsense-cute blend, 7 grand single word.

Roster rules, per column: no ending (last two letters) on more than 3 species in a world; across a tier in a
world at least min(3, count) different shapes; no two species in the same biome share a shape (the Haunted
Nebula event aliens are their own group; a biome with more than 7 species repeats only as often as it must).
Name rules: under 11 characters, unique among all candidates and not another species' current name, never a
real animal alone, Common soft and at most two syllables, Rare and up a harder consonant, and the declared
shape must show in the name.
"""
import argparse
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NOTE = os.path.join(ROOT, "docs", "vault", "01-game-design", "Species-Names.md")
SPECIES = os.path.join(ROOT, "src", "shared", "data", "Species.luau")
GRAND = ("Legendary", "Cosmic", "Secret")
HARD = set("kcgtdxzqj")
DIMINUTIVES = ("let", "kin", "ling", "bit", "et")
HARD_ENDINGS = ("k", "x", "nch", "ng")
# Real animals (and near-animals) a name must not be on its own.
ANIMALS = set(
    """ant ape bat bear bee beetle bird bug bun bunny cat chick cow crab crow cub deer dog dove duck eel elk emu
    finch fish fly fox frog goat goose hare hawk hen hog horse kid kit lamb lark lion lynx mole moose moth mouse
    mule newt owl ox panda pig pony pup rat seal sheep slug snail snake stag swan toad turtle wasp whale wolf worm
    yak zebra hedgehog penguin reindeer tortoise capybara urchin puppy rabbit squirrel otter raccoon badger""".split()
)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def species_rows():
    rows = {}
    for m in re.finditer(r'\{ id = "(\w+)", name = "([^"]+)", concept = "[^"]*", tier = "(\w+)".*?biome = "(\w+)".*?world = (\d)', read(SPECIES)):
        rows[m[1]] = {"now": m[2], "tier": m[3], "biome": m[4], "world": int(m[5])}
    return rows


def parse_note(section):
    """[(heading, [cells])] for every table row under the section."""
    groups, inside, cur = [], False, None
    for line in read(NOTE).splitlines():
        if line.startswith("#"):
            if line.startswith("## "):
                inside = section in line
            cur = None
            if inside and line.startswith("#### "):
                cur = (line[5:].strip(), [])
                groups.append(cur)
        elif inside and cur is not None and line.startswith("|"):
            cur[1].append([x.strip() for x in line.strip().strip("|").split("|")])
    return groups


def letters(name):
    return re.sub(r"[^a-z]", "", name.lower())


def syllables(name):
    w = letters(name)
    n = len(re.findall(r"[aeiouy]+", w))
    if n > 1 and w.endswith("e") and not w.endswith("le"):
        n -= 1
    return max(n, 1)


def hard_letters(w):
    return any(c in HARD for c in re.sub(r"ch", "k", w))


def name_problems(name, shape, tier):
    w, bad = letters(name), []
    if len(name) > 10:
        bad.append(f"{len(name)} characters")
    if w in ANIMALS:
        bad.append("a real animal on its own")
    if tier == "Common":
        if syllables(name) > 2:
            bad.append("a Common over two syllables")
        if re.search(r"[xzq]|ck|c(?!h)", w) or w.count("k") > 1:
            bad.append("a Common that is not soft")
    elif tier not in ("Uncommon",) and not hard_letters(w):
        bad.append(f"a {tier} with no harder consonant")
    if shape == 1 and not (syllables(name) == 1 or (len(w) <= 5 and syllables(name) <= 2)):
        bad.append("shape 1 but not a monosyllable")
    if shape == 2 and (len(w) % 2 or w[: len(w) // 2] != w[len(w) // 2 :]):
        bad.append("shape 2 but not a reduplication")
    if shape == 3 and not w.endswith(DIMINUTIVES):
        bad.append("shape 3 without a diminutive suffix")
    if shape == 5 and not w.endswith(HARD_ENDINGS):
        bad.append("shape 5 without a hard ending")
    if shape == 7 and (tier not in GRAND or len(w) < 6):
        bad.append("shape 7 needs a Legendary-or-up single word of 6+ letters")
    return bad


def roster_problems(label, roster, species, events):
    """roster: {id: (name, shape)}."""
    bad = []
    by_world = collections.defaultdict(list)
    by_tier = collections.defaultdict(list)
    by_biome = collections.defaultdict(list)
    for sid, (name, shape) in roster.items():
        sp = species[sid]
        by_world[sp["world"]].append((sid, name))
        by_tier[(sp["world"], sp["tier"])].append((sid, shape))
        by_biome[("Haunted Nebula" if sid in events else (sp["world"], sp["biome"]))].append((sid, shape))
    for world, items in by_world.items():
        ends = collections.defaultdict(list)
        for sid, name in items:
            ends[letters(name)[-2:]].append(name)
        for end, names in ends.items():
            if len(names) > 3:
                bad.append(f"{label}: world {world} has {len(names)} names ending -{end}: {', '.join(names)}")
    for (world, tier), items in by_tier.items():
        shapes = {s for _, s in items}
        if len(shapes) < min(3, len(items)):
            bad.append(f"{label}: world {world} {tier} has {len(shapes)} different shapes over {len(items)} species")
    for key, items in by_biome.items():
        counts = collections.Counter(s for _, s in items)
        repeats = sum(c - 1 for c in counts.values())
        if repeats > max(0, len(items) - 7):
            dup = [(s, [i for i, x in items if x == s]) for s, c in counts.items() if c > 1]
            bad.append(f"{label}: {key} repeats a shape more than it must: {dup}")
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--section", default="Second pass")
    section = ap.parse_args().section
    species = species_rows()
    groups = parse_note(section)
    problems, rows, events = [], {}, set()
    for heading, cells in groups:
        for c in cells:
            if c[0] in species and len(c) >= 7:
                rows[c[0]] = c
                if heading.startswith("Event"):
                    events.add(c[0])
    missing = sorted(set(species) - set(rows))
    if missing:
        problems.append("no table row for: " + ", ".join(missing))
    seen = collections.defaultdict(list)
    cols = {k: {} for k in "ABC"}
    cols["pick"] = {}
    for sid, c in rows.items():
        shapes = [int(x) for x in re.findall(r"\d", c[6])]
        shapes = shapes * 3 if len(shapes) == 1 else shapes
        if len(shapes) != 3:
            problems.append(f"{sid}: the Shape cell must be one number or a/b/c")
            continue
        names = dict(zip("ABC", c[2:5]))
        for k, shape in zip("ABC", shapes):
            cols[k][sid] = (names[k], shape)
            seen[letters(names[k])].append(sid)
            for p in name_problems(names[k], shape, species[sid]["tier"]):
                problems.append(f"{sid} {k} {names[k]}: {p}")
        letter, _, pname = c[5].partition(" ")
        if letter not in names or names[letter] != pname:
            problems.append(f"{sid}: My pick '{c[5]}' is not one of its A, B or C")
        else:
            cols["pick"][sid] = (pname, shapes["ABC".index(letter)])
    now = {letters(v["now"]): k for k, v in species.items()}
    for key, ids in seen.items():
        if len(ids) > 1:
            problems.append(f"'{key}' appears more than once ({', '.join(ids)})")
        if key in now and now[key] != ids[0]:
            problems.append(f"'{key}' is the current name of {now[key]}, listed under {ids[0]}")
    for label, roster in cols.items():
        if len(roster) == len(species):
            problems += roster_problems("column " + label if label != "pick" else "My pick", roster, species, events)
    if problems:
        print("\n".join(problems))
        return 1
    print("names: clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
