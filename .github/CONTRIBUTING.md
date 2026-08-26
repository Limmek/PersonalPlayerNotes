# Contributing

Notes for contributors and coding agents working on this repository. For the user-facing addon description, see [README.md](../README.md). For repository conventions (feature detection, TOC load order, localization/migration rules), see [AGENTS.md](AGENTS.md).

## Development

- Requires Lua 5.1 syntax/semantics (no runtime beyond the WoW client itself).
- Embedded libraries (AceAddon-3.0, AceConfig-3.0, LibDataBroker-1.1, etc.) are **not** vendored in this repository — see [embeds.xml](../embeds.xml) and [.pkgmeta](../.pkgmeta). They're fetched automatically from their upstream repositories when the addon is packaged (see [Releases](#releases)). For a runnable local copy for manual in-game testing, run [Tools/Install-LocalAddon.ps1](../Tools/Install-LocalAddon.ps1) (PowerShell) — it links a WoW AddOns folder to this checkout (so changes are picked up on `/reload`) and fetches the libraries listed in `.pkgmeta` into `Libs/`. It only needs `git` (no separate SVN client is installed or required; the SVN-hosted externals are fetched with `git svn`, which ships with Git for Windows). Run `.\Tools\Install-LocalAddon.ps1 -Uninstall` to remove the link again. Alternatively, run the [BigWigsMods packager](https://github.com/BigWigsMods/packager) locally to build an actual zip instead of a live link.

## Running checks and tests

[![CI](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml)

All checks below run in [workflows/ci.yml](workflows/ci.yml) on every push and pull request, and never publish anything. A `Makefile` wraps the same commands locally:

| Command              | What it does                                                            |
|----------------------|--------------------------------------------------------------------------|
| `make format`        | Formats all Lua files in-place with [StyLua](https://github.com/JohnnyMorganz/StyLua) (config: [.stylua.toml](../.stylua.toml)) |
| `make format-check`   | Checks formatting without writing changes (same check CI runs)          |
| `make lint`           | Runs [luacheck](https://github.com/mpeterv/luacheck) using [.luacheckrc](../.luacheckrc) |
| `make test`           | Runs the pure-Lua unit tests (no WoW client required) with Lua 5.1      |
| `make validate`       | Runs [Tools/validate-toc.lua](../Tools/validate-toc.lua): checks required TOC metadata, that every referenced file exists, no duplicate file entries, and that `## Version` is still the packager placeholder |
| `make build`          | Builds a local, unsigned addon zip with the BigWigsMods packager (no upload) |
| `make check`          | Runs `format-check`, `lint`, `test`, and `validate` together             |

Equivalent raw commands (if you don't have `make`, e.g. on plain Windows without Git Bash/WSL):
```sh
stylua --check .          # or without --check to write
luacheck .
lua5.1 Tests/test_utils.lua
lua5.1 Tests/test_config.lua
lua5.1 Tests/test_main.lua
lua5.1 Tools/validate-toc.lua
```

## Releases

[![Interface versions](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml)
[![Release](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml)

Releases are fully automated via [workflows/release.yml](workflows/release.yml), and only happen on pull requests merged into `master` (or manual dispatch) — never on every push:

1. The `tag` job runs [K-Phoen/semver-release-action](https://github.com/K-Phoen/semver-release-action) (pinned to `v1.3.2`), which decides whether the merged PR warrants a new semver tag (based on the PR's labels — see that action's docs) and creates the git tag + GitHub release if so. If no new tag is warranted, nothing else in this workflow runs.
2. The `package` job (gated on step 1 actually producing a tag) runs the [BigWigsMods packager](https://github.com/BigWigsMods/packager) (pinned to the exact release `v2.5.1`, not a floating tag) to build a clean release zip (excluding dev-only files per [.pkgmeta](../.pkgmeta)), using the git tag as the addon version (the `.toc`'s `@project-version@` placeholder — see [.luacheckrc](../.luacheckrc)/AGENTS.md — is substituted in at this point), and publishes it to GitHub Releases and CurseForge (project `344967`).
3. Credentials (`CF_API_KEY`, `GITHUB_OAUTH`) are supplied via repository secrets, never hardcoded. These names are what packager `v2.5.1` actually reads (verified from its source) — a future packager upgrade past its unreleased "Normalize api token env vars" change would need `CF_API_TOKEN`/`GITHUB_API_TOKEN` instead.
4. A merge only reaches the `release` workflow's intended effect (an actual publish) if [workflows/ci.yml](workflows/ci.yml) passed first — this repository's branch protection rules on `master` should require the `ci.yml` jobs (`format`, `luacheck`, `tests`, `validate`, `build`) as required status checks, since a workflow file alone cannot enforce that.

[workflows/interface-version.yml](workflows/interface-version.yml) separately keeps the declared `## Interface` versions in [PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc) up to date on a daily schedule.

## Project structure

- [PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc) — addon manifest and load order.
- [PersonalPlayerNotes.lua](../PersonalPlayerNotes.lua) — initialization, menu/tooltip hookups, legacy Shitlist migration.
- [PersonalPlayerNotesConfig.lua](../PersonalPlayerNotesConfig.lua) — AceDB defaults and AceConfig options tables.
- [PersonalPlayerNotesUtils.lua](../PersonalPlayerNotesUtils.lua) — metadata getters, feature detection, SavedVariables migration, GUI helpers.
- [Locales/](../Locales/) — AceLocale string tables (`enUS.lua`, `zhCN.lua`).
- [Tests/](../Tests/) — pure-Lua unit tests runnable outside of WoW.
- [Tools/](../Tools/) — local dev tooling, e.g. [Install-LocalAddon.ps1](../Tools/Install-LocalAddon.ps1) for setting up a runnable local checkout.
- [Tools/validate-toc.lua](../Tools/validate-toc.lua) — pure-Lua TOC/addon-structure validator, used by both CI and `make validate`.
- [embeds.xml](../embeds.xml) / [.pkgmeta](../.pkgmeta) — embedded Ace3 library declarations and packaging config.
- [.stylua.toml](../.stylua.toml) — StyLua formatting config.
- [Makefile](../Makefile) — local developer commands (`format`, `format-check`, `lint`, `test`, `validate`, `build`, `check`).
- [changelog.txt](../changelog.txt) — release changelog consumed by the packager.
- [AGENTS.md](AGENTS.md) — repo-specific conventions for contributors and coding agents.
