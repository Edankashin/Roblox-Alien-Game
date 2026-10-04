# Creature generation

Pipeline from the reference videos, adapted to our roster. Tools seen working in 2026: Claude Design (models with VFX and animation sets plus a Lua installer), 3D AI Studio (meshes with a target polygon count, preferred for phones), Meshy (rigged and animated GLBs), an image model such as Gemini for icon sets and model reference sheets, and Studio MCP `generate_mesh` as the free fallback. Pick one tool per asset type and record the settings that worked here.

## Prompt template (one per species)

> Generate a Roblox-ready creature called [name]: [three-word concept]. Round compact body, big eyes, tiny mouth, short limbs, one bold [colour], stylized low-poly, drawable by a child. One accessory: [attribute]. Animations: idle (looping, job-tied: [job]), walk, work-at-station ([job] loop), catch-reveal (shake, pop, pose), ride ([traversal] if rideable), flee. Tier [tier]: [overlay notes]. Low particle count, mobile-safe. Import 1:1 with an installer .lua. Ask me every question you need before generating.

## Steps
1. Generate commons first, in batches; review silhouettes in greyscale at thumbnail size.
2. Keep one goofy element at every tier.
3. Paste the installer .lua into Studio's command bar, or hand it to Claude through MCP. It rigs the model and imports the animations.
4. Ask Claude Code to wire the species into `src/shared/data/species` and the client renderer.
5. Record what worked and what did not here.

Budget note from the reference: about ten creatures used roughly 30% of a usage allowance.
