"""The Surface pass defaults for a species body: smooth, with no tiled texture map unless the design wants one.

Pure data and functions, no `bpy`, so tools/materials_smooth.py, the unit tests and the Blender tools all read the same rule.
Why it exists (docs/vault/06-art-pipelines/Surface-Pass.md, "No grain (2026-10-15)"): the grain the owner saw on Fenrir and the other
aliens is the normal map of the shared `fur`, `moss` and `scales` sets (plus a mottle from their roughness and colour maps), tiled
over a body 1.5 to 5 studs tall. A render with those maps off is smooth; more samples, a different denoiser or no bump node change
nothing. `stone` (cracked facets) and `ice` (smooth cells with frost lines) are large, deliberate shapes, not grain, so they stay.

The rule, per slot of a materials.json:
- a `texture` key on KEEP_TEXTURE stays, with its `material`;
- any other `texture` key is dropped, and the slot becomes SmoothPlastic when it had no `material` or one the dropped map stood in for
  (Fabric for the fur sets, Grass for the moss set), because Roblox's own Fabric and Grass textures are the same grain once the map is
  gone. A slot on any other material (Neon, Metal, Glass, Ice, Slate...) keeps it: only the map goes.
The vertex gradient, the gloss (`glossy`) and every other field are not touched, and a slot that never had a texture is left alone (the
knitted Fabric scarves and caps stay). Idempotent: a smoothed entry is its own result.
"""

KEEP_TEXTURE = ("stone", "ice")  # texture keys (data/Textures) a slot may still name: cracked stone facets, ice cells
SMOOTH_MATERIAL = "SmoothPlastic"
STAND_IN_MATERIALS = ("Fabric", "Grass")  # the Roblox materials that went with a fur, moss or scales map; they become smooth with it


def keeps_texture(key):
    return key in KEEP_TEXTURE


def smoothed(entry):
    """The entry as the default wants it: a new dict with the key order kept (a slot that had no material gets one where its texture was)."""
    key = entry.get("texture")
    if key is None or keeps_texture(key):
        return dict(entry)
    out = {}
    for name, value in entry.items():
        if name == "texture":
            if "material" not in entry:
                out["material"] = SMOOTH_MATERIAL
            continue
        out[name] = SMOOTH_MATERIAL if name == "material" and value in STAND_IN_MATERIALS else value
    return out


def violations(entry):
    """Why a slot breaks the default (a texture off the allowlist), or []."""
    key = entry.get("texture")
    if key is not None and not keeps_texture(key):
        return ["texture %r is not on the allowlist (%s)" % (key, ", ".join(KEEP_TEXTURE))]
    return []
