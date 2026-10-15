---
tags: [roblox-engine, engine, vfx, species]
aliases: [Species effects, Per-species VFX, SpeciesFx]
up: "[[Roblox-Engine]]"
---
# Species effects

Every alien has its own effect and idle motion, and the rarity ladder is visible in how much of it you see: a Common drops one soft mote now and then, a Secret wears everything, in the dark variant. Back to [[Roblox-Engine]]. The older tier aura (a point light and a glow sprite on a Rare or better wild spawn) is still the base layer; this adds on top of it.

## Where it lives

| What | File |
|---|---|
| The rows: `Species` (35), `Tiers` (the ladder), `Caps`, `Attach` (body regions), `Extras`, `Dark`, `Look`, `Motion`, `Reduced` | `src/shared/data/Effects.luau` |
| Types `EffectLayer`, `IdleMotion`, `SpeciesFx`, `TierFxRule`, `AttachPoint` | `src/shared/types/Types.luau` |
| The pure rules: `LayersFor` (the tier gate), `Resolve`, `PickActive`, the idle, beam, pulse and orbit clocks | `src/shared/EffectsMath.luau`, tested by `tests/Effects.spec.luau` |
| The drawing (client only) | `src/client/World/SpeciesFx.luau` |
| Callers | `WildRenderer`, `CampRenderer`, `CompanionRenderer` |
| `Config.VfxFxRecheckSeconds` | `src/shared/data/Config.luau` |

Lengths in a layer are **fractions of the alien's height**, so one row fits a Tiny and a Huge of the same species and the data names no stud. The only studs and degrees are the idle amplitudes. Layers hang on **regions** (`Top`, `Back`, `BackL`, `BackR`, `Tail`, `Eyes`, `Mouth`, `Feet` ...), fractions of the alien's measured bounds, so a new model needs no new numbers.

## The tier gate

`EffectsMath.LayersFor(speciesId, tier)` takes the first `layersAllowed` of the species' layers (strongest first), holds them to 4 beams and 1 light, and adds a trail and an orbit for a tier whose rule asks for them if the species has none (in the species' own colour). Common and Uncommon draw 1, Rare 2, Epic 3, Legendary and up all of them; Legendary adds a ground ring, Cosmic an orbit and a trail, Secret the dark variant (colours sink toward `Dark.Color`, emitter glow shrinks so smoke reads as smoke). `rateScale`, `sizeScale` and `lightScale` grow up the ladder; lint (`tools/lint_data.py`) and the spec both fail a ladder that falls.

## Lightning: Beams

A `Beam` draws between two Attachments. Thunderhog's lightning is one Beam from `BackL` to `BackR` (the quills), `FaceCamera = true`, `LightEmission = 1`, `Segments = 8`. The bolt is not a texture: the bend is `CurveSize0` and `CurveSize1` redrawn at random, and the bolt only exists for `Look.BeamFlashSeconds` (0.18 s) once every `flicker` seconds (2 for Thunderhog), with `Look.BeamSteps` redraws inside a strike so it crackles. The strike is a pure function of `os.clock()` (`EffectsMath.BeamState`), each beam slid by its own offset so two beams on one alien do not flash together. Between strikes the Beam is `Enabled = false`. Static sparks are a separate Emitter on the same region. Both Attachments must sit on parts that move together, which they do: for a Model they are on one invisible `FxAnchor` part at the pivot.

## Emitters, lights and caps

- Rate is `layer.rate * rateScale`, then `min(that, cap)` per emitter: 100 a second on a device with a touch screen (`UserInputService.TouchEnabled`), 400 on desktop. Lint checks that the biggest data rate times the biggest `rateScale` is under the phone cap.
- Only the **nearest 12** aliens (`Caps.MaxActive`) within `Caps.ActiveDistance` of the camera draw their species layers; the rest keep the tier aura. The ranking reruns every `Config.VfxFxRecheckSeconds`, and **nothing is built for an alien until it ranks**, so a field of 100 far spawns costs a flag each. An alien that falls out has its layers switched off, not destroyed.
- One species light per alien (`Caps.MaxLights`), shadows off. The Wild aura light is a second one on the same alien.
- A hidden (blizzard) or still-silhouetted alien calls `SetShown(false)` and shows nothing: lightning off a dark shape would give the species away.

## Idle motion without drift

The renderers write each alien's pivot **absolutely** every frame (the bob), and skip it for culled aliens. A tween on the pivot, or an offset added after the renderer, would be overwritten on a frame they run first and doubled on a frame they skip. So the renderer composes it: where it did `model:PivotTo(modelBase + lift)` it now calls `SpeciesFx.Place(model, modelBase + lift)`, which writes `pivot * idle offset` from `os.clock()` and a per-alien phase. Same clock, same pose, however many frames were skipped. Bob and Hover never go below the feet. A Flap swings the named `WingL` and `WingR` parts about hinges worked out from the pivot, also absolute; a model without those parts bobs instead. **Breathe is a rock about the feet with a little lift, not a scale**: `ScaleTo` every frame would also rescale every Attachment, emitter and Beam parented under the model and pile up float error. Spin does not turn an alien whose renderer owns its facing (camp, companions).

## Reduced Motion

`Prefs.ReducedMotion()` holds the idle motion and replaces every emitter, beam, trail and orbit with one still glow: the species' own light held steady (no pulse), or a light of `Reduced.GlowBrightness` in its first layer's colour. A change rebuilds on the next ranking.

## Left out, on purpose

- The reveal card and the Codex are UI and do not show effects yet.
- `HomeRenderer` (habitat displays) and the Hangar do not attach; the three renderers above do.
- `SpeciesFx.sound` is in the type and the lint but nothing plays it yet.
- Sprites whose `Icons.Particles` id is still 0 (Ember, Glow, Ring, Sparkle, Star) draw as the soft default particle until uploaded; nothing needs to change when they are.
- Placeholder parts rolled onto their side (cylinders) keep "up" up for placement, but Breathe's rock needs a model.

Studio check: `docs/TESTING.md` "Species effects". Session notes: [[2026-10-15]].
