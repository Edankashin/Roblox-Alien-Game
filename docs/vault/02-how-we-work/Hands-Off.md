# Hands-off: running the project with as little manual work from Ethan as possible

Written 2026-10-07 after Ethan asked for a way to stop doing manual steps. Everything below uses official tools only (Roblox Open Cloud, Rojo, Roblox Studio's own MCP server, the Claude desktop app's computer use, the Codex CLI).

## Who does what

| Who | Does | How Ethan hears about it |
|---|---|---|
| Coordinator (the cloud Claude session) | Designs, builds and reviews the game; writes Codex cards; sends the Mac its jobs with `send_message`; reads Codex's reports from git | One message per finished block |
| The Mac's Claude session | Everything that needs the Mac: Studio through the Studio MCP server; the clicks MCP cannot make (Studio's Publish, the Test tab's Clients and Servers run) through computer use; the Open Cloud scripts with the key from its shell; starting Codex runs; pushing results | Reports to the coordinator; asks Ethan only for the approvals its own settings require |
| Codex | Tooling, tests, lints and reports from `Codex-Queue.md`; reports land in `Codex-Reports.md` in git, so nobody pastes them | Through the coordinator |
| Ethan | Approvals on the Mac, decisions, money, identity and legal steps, and playing the game (below) | Asked one line at a time |

## One-time setup (Ethan, about 15 minutes)

1. **Give the Open Cloud key three more permissions.** Creator Dashboard (create.roblox.com/dashboard) → left menu **Open Cloud** → **API Keys** → the key the Mac already uses → **Edit**. Under Access Permissions, for this experience add: **universe-places** with Write, **game-pass** with Read and Write, **developer-product** with Read and Write. Save. The key itself does not change and stays only in the Mac's `~/.zshrc`.
2. **Turn on computer use for the Mac's Claude app** (Claude desktop app settings), and when the session first asks to control Roblox Studio, allow it. It is used only for the buttons MCP cannot press.
3. **Keep the Mac available.** Plugged in, Roblox Studio and the Claude app open and signed in, and automatic sleep off while plugged in (System Settings → Battery or Energy → Options).
4. Tell the coordinator "setup done".

The Mac session still asks before it runs commands, uploads or publishes, as its settings require. How often it asks is Ethan's own setting in the Claude app on the Mac; the coordinator does not write or push permission rules for any session.

## What then runs without Ethan's hands

| Manual part today (owner guide) | Replaced by | Ready when |
|---|---|---|
| Part C: creating game passes and products, copying ids | `tools/create_products.py --apply` on the Mac (Codex card C22) writes the ids into `Shop.luau` and pushes; Ethan approves the run in the Mac window | C22 reviewed and step 1 above done |
| Parts A and H: publishing and republishing the three places | The Mac publishes from Studio with computer use now; later `tools/publish.py --apply` from the repo with no Studio at all (C23, plus the model table C24 and the coordinator's runtime model loader) | Now (Studio route); headless after C23, C24 and the loader |
| A8: the World 1 place id | The Mac reads it from Studio (`game.PlaceId`) or the Open Cloud universe and writes it into `Worlds.luau` | Now |
| Part D: two-player tests | The Mac runs Studio's Clients and Servers test with computer use and drives both windows | After step 2 |
| Part E: starting Codex and pasting its reports | The Mac starts `codex exec` with the batch prompt when the queue has open cards; reports are already in git | Now, with Ethan's approval of the run |
| Relaying messages between sessions | The coordinator and the Mac session message each other directly | Now |

## What stays Ethan's (by design, not by missing tooling)

- **Approvals on the Mac**: the Mac session's permission prompts are his to answer.
- **Decisions**: the coordinator asks one line at a time ("build playtime gifts? yes or no").
- **Money**: spending Robux on ads or sponsorships, payouts, and anything else that costs money.
- **Identity and legal**: the experience questionnaire and content maturity answers, privacy and compliance forms, two-step verification prompts, ID verification, and switching the game to public the first time. These are Ethan's account's legal statements; no tool should make them for him.
- **Playing it**: how the game feels to a person is the one input no tool replaces.
