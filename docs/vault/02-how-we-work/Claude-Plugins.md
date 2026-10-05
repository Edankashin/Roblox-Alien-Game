# Claude Code plugins and skills for this project

What the Roblox AI-dev community installs (reference video ZPL8Hb7yS, batch 4), and what we do with each. Rule from the Studio page applies here too: one registration per tool, at project scope, and nothing installed by a script. Each install is one deliberate command in the Mac terminal, followed by a dry run that proves it does not fight `CLAUDE.md`, `.mcp.json` or the vault.

| Tool | What it is | Our decision | Command |
|---|---|---|---|
| Roblox Studio MCP | Claude sees and edits the open place | In (see `03-studio-and-mcp/Connection.md`) | already in `.mcp.json` |
| Blender MCP | Claude builds and edits models in Blender | In (see `06-art-pipelines/Blender-MCP.md`) | already in `.mcp.json` |
| Roblox Dev (ivar-anon) | Luau toolkit: exploit-proof remotes, safe DataStores, strict typing, client/server split | Adopt after a dry run: it matches our server-authority and strict-mode rules; check it does not override CLAUDE.md | `/plugin marketplace add ivar-anon/roblox-dev` then `/plugin install roblox-dev@roblox-dev` |
| Roblox Studio skill (ShiroKSH) | Building and placement: maps, arenas, object placement, level design | Adopt for World 2 map work, through the Mac session | `/plugin marketplace add ShiroKSH/skills` then `/plugin install roblox-studio@skills` |
| Superpowers | Plans more before big features | Try on the World 2 build only; say "use Superpowers for this" | `/plugin install superpowers@claude-plugins-official` |
| Roblox Claude Skills | Map, UI, debugging, API help, cleanup, setup; Rojo-flavoured | Skip: it conflicted with the creator's other skills and overlaps the two above | |
| Graphify | Knowledge graph of the project | Skip: the vault and the sourcemap do this for a project our size | `pip install graphifyy`, `graphify install`, `/graphify` |
| Ponytail | "Lazy senior dev" YAGNI mode | Skip: CLAUDE.md already asks for the smallest change; token saving unproven | |
| Agent Skills | A general skills collection | Skip until a specific skill is missing | |

## Our own skills

Project skills live in `.claude/skills/<name>/SKILL.md` and load automatically when the task matches.

- `import-model`: importing a GLB or FBX from `assets/models/` into Studio and wiring it to a species. Written from the creator's "model importing" skill, which cut a three-to-five-minute Claude import to one step.

## Dry-run checklist before adopting a plugin

1. Install on the Mac in the repo, in project scope.
2. Start a fresh Claude Code session; `/mcp` still lists `Roblox_Studio` and `blender`; `/plugin` lists the new one.
3. Ask for a one-line change that CLAUDE.md governs (a number into `src/shared/data`, a string into the strings table) and confirm the plugin did not steer it elsewhere.
4. `./tools/analyze.sh` prints `analyze: clean`.
5. Record the result here with the date; remove the plugin if any step fails.

## Add-ons asked for on 2026-10-05: verdicts

Rules for this section: only repos with more than 1,000 GitHub stars count as credible for an install; an add-on that fails its purpose is skipped even when popular. Star counts were read on 2026-10-05 from each repo's github.com page with WebFetch (the GitHub API URL returned HTTP 403 through WebFetch, so no API numbers); counts are as displayed and rounded by GitHub. Nothing here is installed yet. Each install is one deliberate command in the Mac terminal, followed by the dry-run checklist above.

| Add-on | Real repo and stars | What it actually is | Mac install | Verdict | Risk |
|---|---|---|---|---|---|
| Omniroute | [diegosouzapw/OmniRoute](https://github.com/diegosouzapw/OmniRoute), 73.3k, MIT. Name is ambiguous: ChrisCompton/omniroute and a same-description 91car/OmniRoute (not checked) also exist | Local OpenAI-compatible gateway over 357 providers (Claude, GPT, Gemini, DeepSeek, Qwen, free tiers). Claude Code connects with `ANTHROPIC_BASE_URL=http://localhost:20128/v1`. On quota exhaustion it falls back through subscription, API-key, cheaper, then free providers, and can pool several Claude accounts ("Quota-Share routing") | `npm install -g omniroute` (not recommended) | Skip. Meets the star bar, fails the purpose | Pooling subscription accounts to dodge limits risks a ban (terms below). Falling back to GPT, Gemini, DeepSeek or Qwen changes the model, so "cognition does not waver" cannot hold |
| claude-mem | [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem), 96.5k, Apache-2.0, v13.31.0 | Plugin that records what Claude does in a session, compresses it with an AI model, and injects relevant memory into later sessions | `claude plugin marketplace add thedotmack/claude-mem` then `claude plugin install claude-mem@thedotmack`; or `npx claude-mem install` | Adopt as a one-week trial on one Mac, with the provider set deliberately (see risk) | Data lives locally (`~/.claude-mem/settings.json`, SQLite, Chroma). The README's default provider is the hosted "CMEM Pro" (email sign-in); alternatives are your own OpenRouter or Gemini key or your Anthropic plan. Choosing the plan spends your own usage; choosing a hosted provider sends session observations to it. Wrap secrets in `<private>` tags. Needs Node 20+; installs Bun and uv |
| Headroom | [chopratejas/headroom](https://github.com/chopratejas/headroom), now [headroomlabs-ai/headroom](https://github.com/headroomlabs-ai/headroom), 74.4k, Apache-2.0 (both URLs show the same 74.4k). Ambiguous: daveeed1/headroom and PlayForm/Headroom also exist | Context compression layer: compresses tool outputs, logs, files, RAG chunks and history before they reach the model. Library, local proxy, MCP server. Claims 20% fewer tokens for coding agents, 60 to 95% for JSON; savings are estimated, not measured, by default | `pip install "headroom-ai[all]"` (Python 3.10+) then `headroom wrap claude`; or `headroom proxy --port 8787` and point `ANTHROPIC_BASE_URL` at it | Later. Not a plugin, so it stays out of the settings block | Lossy compression changes what Claude reads, which is a cognition risk; it sits in the request path of every call; optional anonymous metrics beacon. Gains are small on prose and short sessions, which is most of our work |
| Claude Code Setup | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup), plugin `claude-code-setup`; parent repo 37.4k stars; 195,067 installs on [claude.com/plugins/claude-code-setup](https://claude.com/plugins/claude-code-setup). Ambiguous: rse/claude-code-setup is an unrelated personal repo | Official Anthropic plugin. Read-only: scans the codebase and recommends MCP servers, skills, hooks, subagents and slash commands (top one or two per category). Changes no files | `claude plugin install claude-code-setup@claude-plugins-official` (the official marketplace is added automatically on first interactive start) | Adopt now. Run it once, read the suggestions, apply by hand | Low. Suggestions can disagree with CLAUDE.md, so the one-registration rule still decides |
| Task Observer | [rebelytics/one-skill-to-rule-them-all](https://github.com/rebelytics/one-skill-to-rule-them-all), skill `task-observer`, 3.2k, CC BY 4.0. A second copy exists in iamneilroberts/claude-skills; the original is this one | A meta-skill that watches sessions and logs corrections and skill gaps, then proposes improvements to other skills for human review. It does not learn your style broadly, and it never edits skills by itself | `npx skills add rebelytics/one-skill-to-rule-them-all --skill task-observer`, then add its activation line to CLAUDE.md. Not a plugin marketplace entry | Later. We have one project skill (`import-model`); revisit at five or more | Needs an edit to CLAUDE.md, which this project governs tightly; writes observation logs into the repo; per-session token overhead unmeasured |

Sources, all read 2026-10-05: <https://github.com/diegosouzapw/OmniRoute>, <https://raw.githubusercontent.com/diegosouzapw/OmniRoute/main/README.md>, <https://github.com/thedotmack/claude-mem>, <https://raw.githubusercontent.com/thedotmack/claude-mem/main/README.md>, <https://raw.githubusercontent.com/thedotmack/claude-mem/main/.claude-plugin/marketplace.json>, <https://github.com/headroomlabs-ai/headroom>, <https://github.com/chopratejas/headroom>, <https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup>, <https://github.com/rebelytics/one-skill-to-rule-them-all>, <https://raw.githubusercontent.com/rebelytics/one-skill-to-rule-them-all/main/README.md>.

### Keeping working when the subscription limit is hit

Rotating several Claude subscription accounts to get around usage limits is against Anthropic's terms. The [Consumer Terms](https://www.anthropic.com/legal/consumer-terms) (read 2026-10-05) say you may not share account login information or credentials, may not access the services by automated means except with an Anthropic API key, and must not bypass protective measures. The [Claude Code legal page](https://code.claude.com/docs/en/legal-and-compliance) (read 2026-10-05) says Pro and Max limits assume ordinary, individual usage, that Anthropic does not permit routing requests through Free, Pro or Max plan credentials on behalf of users, and that credentials or session tokens may not be intermediated. I found no clause that names "multiple accounts" word for word, so this is the closest wording; treat pooled-account routing as a ban risk. OmniRoute's own README marks 13 providers "avoid" in its terms-risk catalog.

The legitimate options, which keep the same Claude models and need no router:

1. Bill an Anthropic API key. Claude Code reads `ANTHROPIC_API_KEY` natively; per the [authentication page](https://code.claude.com/docs/en/authentication) (read 2026-10-05) it asks once to approve the key and then uses it ahead of the subscription login, billed to the Console account. In the Mac terminal: `export ANTHROPIC_API_KEY=...`, start `claude`, check `/status`; `unset ANTHROPIC_API_KEY` returns to the subscription.
2. Wait for the reset.
3. Routing to a non-Claude model (any router above) changes the model and therefore the cognition. Only do it deliberately, for a worker whose brief is fully specified, never to hide a limit.

### Task 2 survey: credible repos for this team

Stars read from each repo's github.com page on 2026-10-05. "Below bar" means under 1,000 stars; for Roblox tooling that is normal because the ecosystem is small, so those rows are judged on fit and need the team's explicit OK before an install.

#### (a) Token spend

| Repo | Stars | What it gives us | Verdict | Reason |
|---|---|---|---|---|
| [ryoppippi/ccusage](https://github.com/ryoppippi/ccusage) | 18.9k | Token and cost reports per day and session from local data | Adopt now | Measures everything else; install first |
| [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | 82.4k | Single Rust binary that compresses shell output (claims 60 to 90%); `brew install rtk` | Adopt now as a trial | Rojo, git and analyzer output is shell-heavy; judge with ccusage after one baseline week |
| [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) | 110k (as displayed) | Skill that makes Claude's replies terse (claims 65%) | Later | Could degrade design prose; first see whether output tokens are a meaningful share |
| [musistudio/claude-code-router](https://github.com/musistudio/claude-code-router) | 37.6k | Local router across providers and models, own API keys, MIT | Skip | Changes the model like OmniRoute; only for a deliberate cheap-worker experiment |
| [headroomlabs-ai/headroom](https://github.com/headroomlabs-ai/headroom) | 74.4k | Context compression proxy | Later | Lossy and in the request path; see verdict table |
| [mksglu/context-mode](https://github.com/mksglu/context-mode) | 25.5k | Sandboxes tool output (claims 98%), session memory, via MCP and hooks | Later | Overlaps rtk and claude-mem; Elastic License v2 is source-available, not open source |
| [diegosouzapw/OmniRoute](https://github.com/diegosouzapw/OmniRoute) | 73.3k | Multi-provider gateway with RTK and Caveman compression | Skip | Purpose fails; see verdict table |
| [yamadashy/repomix](https://github.com/yamadashy/repomix) | 28.7k | Packs a repo into one file for chat tools | Skip | Claude Code reads files on demand; the batch-read rule covers it |
| [zilliztech/claude-context](https://github.com/zilliztech/claude-context) | 12.6k | Semantic code search MCP | Skip | Needs Zilliz Cloud and an OpenAI key; our repo is small |
| [madhan230205/token-reducer](https://github.com/madhan230205/token-reducer) | 48 | Local retrieval layer (listed in Token-Economy.md) | Skip | Far below the 1,000-star bar |

#### (b) Memory and continuity across sessions

| Repo | Stars | What it gives us | Verdict | Reason |
|---|---|---|---|---|
| [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | 96.5k | Automatic cross-session memory plugin | Adopt (trial) | Fills the gap between vault notes and what a session just did; choose the provider first |
| [steveyegge/beads](https://github.com/steveyegge/beads) | 27.6k | Dolt-backed issue tracker for agents (MIT) | Later | Task continuity is useful, but `docs/PRE_PRODUCTION.md` already holds the checklist |
| [basicmachines-co/basic-memory](https://github.com/basicmachines-co/basic-memory) | 4.1k | Local Markdown notes served over MCP (AGPL-3.0) | Later | Duplicates `docs/vault/`, which is already local Markdown |
| [mem0ai/mem0](https://github.com/mem0ai/mem0) | 66.6k | Memory layer SDK for building agents and apps | Skip | Infrastructure for products, not a Claude Code add-on |
| [supermemoryai/claude-supermemory](https://github.com/supermemoryai/claude-supermemory) | 2.8k | Hosted memory plugin | Skip | Needs a Supermemory account and API key; memory leaves the machine |

#### (c) Claude Code speed and workflow

| Repo | Stars | What it gives us | Verdict | Reason |
|---|---|---|---|---|
| [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 37.4k | Anthropic's marketplace (`claude-code-setup`, `commit-commands`) | Adopt now | First-party; no extra marketplace to trust |
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 55.1k | Curated list of skills, hooks, commands | Adopt now | Zero install; the place to look before building our own |
| [sirmalloc/ccstatusline](https://github.com/sirmalloc/ccstatusline) | 13.2k | Customisable status line (context and cost visible); `npx -y ccstatusline@latest` | Adopt now | Makes spend visible; pin a version instead of `@latest` |
| [obra/superpowers](https://github.com/obra/superpowers) | 295.5k | Planning and TDD skill framework | Later | Keep the existing decision above: World 2 build only |
| [anthropics/skills](https://github.com/anthropics/skills) | 179.8k | Official example skills | Later | Copy patterns for our own skills; we do not make Office files |
| [smtg-ai/claude-squad](https://github.com/smtg-ai/claude-squad) | 8.6k | Many agents in isolated workspaces (AGPL-3.0) | Later | Useful once both people run parallel sessions |
| [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates) | 32.4k | CLI that installs agents, commands, hooks from a catalogue | Skip | Breaks the one-registration-per-tool rule |
| [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 273k | A whole harness: skills, memory, security, workflows | Skip | Large bundle that would compete with CLAUDE.md |

#### (d) Roblox development

| Repo | Stars | What it gives us | Verdict | Reason |
|---|---|---|---|---|
| [rojo-rbx/rojo](https://github.com/rojo-rbx/rojo) | 1.8k | Filesystem to Studio sync | Adopt now (in use) | Pinned in `rokit.toml` |
| [JohnnyMorganz/StyLua](https://github.com/JohnnyMorganz/StyLua) | 2.3k | Deterministic Luau formatter; v2.5.2 shown | Adopt now | One pinned line in `rokit.toml` ends style drift between two people and Claude |
| [luau-lang/luau](https://github.com/luau-lang/luau) | 5.9k | The language and type checker we target | Adopt now (in use) | Strict mode is already a project rule |
| [JohnnyMorganz/luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) | 545, below bar | Language server; `tools/analyze.sh` runs it | Adopt now (in use) | Pinned in `rokit.toml`; the analyzer behind the pre-commit check |
| [MadStudioRoblox/ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) | 340, below bar | Session-locked DataStore saving, Apache-2.0 | Adopt now | Named in `docs/PRE_PRODUCTION.md` and matches the saves rule; needs team OK for the star bar |
| [rojo-rbx/rokit](https://github.com/rojo-rbx/rokit) | 468, below bar | Toolchain manager | Adopt now (in use) | `rokit.toml` already exists |
| [lune-org/lune](https://github.com/lune-org/lune) | 957, below bar | Run Luau outside Studio | Later | Could validate data tables without Studio; `tools/` has Python helpers for data tables today |
| [Kampfkarren/selene](https://github.com/Kampfkarren/selene) | 828, below bar | Lua linter | Later | Add only if `analyze` misses lint issues |
| [UpliftGames/wally](https://github.com/UpliftGames/wally) | 499, below bar | Package manager | Later | No third-party packages yet; one system per change |
| [Sleitnick/RbxUtil](https://github.com/Sleitnick/RbxUtil) | 466, below bar | Signal, Trove and other utilities | Later | Copy a single module when needed |
| [evaera/roblox-lua-promise](https://github.com/evaera/roblox-lua-promise) | 350, below bar | Promise library | Later | Only if async chains tangle |
| [SirMallard/Iris](https://github.com/SirMallard/Iris) | 355, below bar | Immediate-mode debug UI | Later | Studio debug panels only; player UI is code-built from the theme |
| [roblox-ts/roblox-ts](https://github.com/roblox-ts/roblox-ts) | 1.3k | TypeScript to Luau | Skip | CLAUDE.md mandates Luau strict |
| [dphfox/Fusion](https://github.com/dphfox/Fusion) | 797, below bar | Reactive UI library | Skip | UI is built in code from the theme module |
| [jsdotlua/react-lua](https://github.com/jsdotlua/react-lua) | 571, below bar | React 17 port | Skip | Same reason as Fusion |
| [Roblox/roact](https://github.com/Roblox/roact) | 625, below bar | Older React-style UI | Skip | Repo says deprecated; points to react-lua |
| [Sleitnick/Knit](https://github.com/Sleitnick/Knit) | 630, below bar | Server and client framework | Skip | Archived 2024-07-31, no further updates |
| [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server) | 493, below bar | Standalone Studio MCP | Skip | Archived 2026-04-03; Roblox points to the built-in Studio MCP |
| [matter-ecs/matter](https://github.com/matter-ecs/matter) | 115, below bar | ECS library | Skip | Not needed for lightweight alien records |

### Proposed team plugin config (not created; for `.claude/settings.json`)

Only the add-ons that passed and install as plugins are listed: Claude Code Setup and claude-mem. OmniRoute is skipped, Headroom and Task Observer are later and are not plugins in any case.

```json
{
  "extraKnownMarketplaces": {
    "thedotmack": {
      "source": { "source": "github", "repo": "thedotmack/claude-mem" }
    }
  },
  "enabledPlugins": {
    "claude-code-setup@claude-plugins-official": true,
    "claude-mem@thedotmack": true
  }
}
```

Key names, read from the Claude Code docs on 2026-10-05:

- `extraKnownMarketplaces` is an object keyed by the marketplace's own `name`; each entry has a `source` object whose `source` field names the type (`github` with `repo`, or `git` with `url`), plus optional `ref`, `path` and `autoUpdate`. The marketplace name `thedotmack` comes from the `name` in claude-mem's `.claude-plugin/marketplace.json`. Source: <https://code.claude.com/docs/en/plugins/org> ("Require a marketplace and its plugins").
- `enabledPlugins` is an object whose keys are `plugin-name@marketplace-name`, set to `true` or `false`. Source: the same page, and <https://code.claude.com/docs/en/plugins/loading> ("Find where a plugin came from").
- `claude-plugins-official` needs no `extraKnownMarketplaces` entry when one of its plugins is enabled; that `enabledPlugins` entry declares the marketplace by itself (plugins/org page).
- Repository `extraKnownMarketplaces` entries apply only after each teammate trusts the folder. A plugin whose marketplace lists a relative path loads from the marketplace copy; one with an external source shows `Plugin "<name>" is enabled in project settings but isn't installed` until each person runs `claude plugin install <name>@<marketplace> --scope project` once. Cloud sessions do not load either key. Sources: plugins/org and plugins/loading above, and <https://code.claude.com/docs/en/plugins/install>.
- Discrepancy to settle on the Mac: the settings reference page (<https://code.claude.com/docs/en/settings-reference>, as WebFetch returned it) describes `extraKnownMarketplaces` as an array and `enabledPlugins` keyed by `github:owner/repo`, which contradicts the three pages above. The block uses the shape the three pages agree on. Before committing it, run `claude plugin marketplace add thedotmack/claude-mem` and `claude plugin install claude-code-setup@claude-plugins-official --scope project`, which write these keys themselves, and compare their output with this block.
- Before enabling claude-mem for both people, each teammate sets the memory provider in `~/.claude-mem/settings.json` (a per-user file), and the team pins the marketplace with a `ref` once it picks a release tag.

**Installed on the Mac, 2026-10-05:** `claude-code-setup@claude-plugins-official` and `claude-mem@thedotmack` (user scope; claude-mem asks for its memory provider on first run, choose local). `npm install -g ccusage` failed with EACCES on the stock Homebrew Node, so ccusage runs as `npx -y ccusage daily` instead; the setup script says so.
