# Token economy

How this project keeps Claude Code spend down without losing output quality. Measured, not guessed: install `ccusage` (the standard usage reporter) on the Mac and read it weekly.

## Rules we apply here

1. **Right model per job.** The coordinating session plans, reviews and wires. Build workers run on Sonnet with a complete brief (file ownership, the contract, what to read, what to report); Sonnet on a well-specified build is as good as the larger model at a fraction of the cost. Design decisions, reviews of test findings and anything ambiguous stay on the larger model.
2. **Briefs name the files; workers read them in one or two commands.** No exploratory browsing. A worker that needs something outside its list stops and says so.
3. **Terse reports.** A worker's report is under 300 words: files, public API, deviations. No restating the brief.
4. **Batch reads, write whole files.** One shell command reads everything a step needs; one script applies every edit. Never re-read a file to confirm an edit.
5. **Contracts first.** Types, data and strings are written by the coordinator before workers start, so two workers never touch the same file and nothing is rewritten.
6. **Test scripts in the repo, results by message.** The Mac session reads `docs/TESTING.md`, plays, and sends pass/fail per step with the console verbatim; the coordinator fixes from the report rather than re-deriving.
7. **Compact on purpose.** `/compact` before a new milestone when the transcript is long; the vault and `docs/TESTING.md` hold the durable state, so nothing is lost.
8. **No chatter.** Status messages say what changed and what is next, in a few lines.

## Tools worth evaluating (not yet installed)

- `ccusage`: usage and cost per session and per day; the one to install first.
- `caveman` (a Claude Code skill that shortens outputs) and `RTK` (a hook that compresses shell output): both claim large output-token savings; try one at a time, measured with ccusage, and keep it only if the game work stays as good.
- `token-reducer`: a local retrieval layer that feeds only relevant code chunks; heavier to set up, for when the codebase outgrows the batch-read rule.

Sources: [free GitHub repos that cut the Claude Code token bill](https://www.deployhq.com/blog/free-github-repos-for-claude-code), [12 ways to cut token consumption](https://www.firecrawl.dev/blog/claude-code-token-efficiency), [token-reducer](https://github.com/madhan230205/token-reducer), [GitHub token-optimization topic](https://github.com/topics/token-optimization?o=desc&s=stars).

Verified on 2026-10-05, star counts as shown on each repo's GitHub page (the GitHub API returned HTTP 403 through WebFetch, so none are API numbers): [ccusage](https://github.com/ryoppippi/ccusage) 18.9k (usage and cost reports, install first), [RTK](https://github.com/rtk-ai/rtk) 82.4k (shell-output compressor, `brew install rtk`, trial it after one ccusage baseline week), [caveman](https://github.com/JuliusBrussee/caveman) 110k as displayed (terse replies, later, because it could thin design prose), [Headroom](https://github.com/headroomlabs-ai/headroom) 74.4k (compression proxy, later, because it is lossy and sits in every request), [context-mode](https://github.com/mksglu/context-mode) 25.5k (Elastic License v2, later), and [claude-code-router](https://github.com/musistudio/claude-code-router) 37.6k plus [OmniRoute](https://github.com/diegosouzapw/OmniRoute) 73.3k (routers that swap the model, skipped). The `token-reducer` repo named above has 48 stars, far below the project's 1,000-star bar, so do not install it. The star counts and the vendors' savings figures (60 to 90%, 65%, 98%) are claims until ccusage measures them here; the verdicts and the per-repo detail are in `Claude-Plugins.md`, section "Add-ons asked for on 2026-10-05: verdicts".
