# Contributing

Development workflow for this repository. Mandatory rules for coding agents are in [AGENTS.md](../AGENTS.md), the code map and data model in [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md), and the publishing procedure in [docs/RELEASING.md](../docs/RELEASING.md). The user-facing addon description is [README.md](../README.md).

## Setup

The addon is Lua 5.1 and needs no build step. The tools below are used by the local pipeline; on a fresh Windows machine install them first.

| Tool | Used for | Notes |
|------|----------|-------|
| Git | version control | `core.autocrlf=true` on Windows: the index holds LF, the working copy CRLF |
| Lua 5.1 | unit tests, TOC and changelog scripts | `dev.ps1` looks for `lua5.1`, `lua`, then `C:\Program Files (x86)\Lua\5.1\lua.exe` |
| StyLua 2.5.2 | formatting | `winget install --id JohnnyMorganz.StyLua --version 2.5.2 -e`; the version matches CI |
| Luacheck | linting | place `luacheck.exe` in `Tools\` (it is gitignored, `*.exe`) or on `PATH` |
| Git Bash, Subversion CLI | only the package dry run at the end of `dev.ps1` | `bash.exe`, `svn.exe` |
| `zip` (in Git Bash), or 7-Zip as fallback | creating the zip in the package dry run | `dev.ps1` uses `zip` when Git Bash has it and falls back to `7z.exe` only when it does not; one of the two is needed |
| GitHub CLI (`gh`) | optional: inspecting workflow runs | |

The Ace3 libraries are not committed (`Libs/*` is gitignored); the packager fetches them from [.pkgmeta](../.pkgmeta). The unit tests stub them and do not need `Libs/`.

For manual testing in the game client, run [Tools/Install-LocalAddon.ps1](../Tools/Install-LocalAddon.ps1). It links your WoW AddOns folders to this checkout (changes load on `/reload`) and fetches the libraries into `Libs/` with `git svn` and `git clone`. `.\Tools\Install-LocalAddon.ps1 -Uninstall` removes the links. It changes files outside the repository, so run it deliberately. To get an actual zip instead of a live link, the last step of `.\Tools\dev.ps1` runs the BigWigsMods packager in dry-run mode and writes the zip to the gitignored `.release/` folder.

## Development workflow

1. Work on `master` (`git switch master`, `git pull`). Never develop on `release`.
2. Find the owning file and an existing pattern before writing code ([docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)).
3. Make the smallest change that solves the problem. Add or update tests for isolable logic, and update both locale files for new text.
4. While iterating, run single test files (see [Running checks](#running-checks)).
5. Before finishing, run `.\Tools\dev.ps1` directly on `master` and read it through to `All local checks completed successfully.`.
6. Review `git diff`, then commit.

Step-by-step workflows for common tasks are in [.github/skills/](skills/).

## Coding conventions

- Lua 5.1 syntax and semantics only. The code runs inside the WoW client.
- Formatting is whatever StyLua produces with [.stylua.toml](../.stylua.toml): 4 spaces, 120 columns, double quotes preferred, Unix line endings. Do not hand-format against it.
- Addon behavior is written as methods on the global `PersonalPlayerNotes` object (`function PersonalPlayerNotes:Name()`). A doc comment `--[[ ... ]]` above a function explains what the code cannot show on its own.
- Option `get`/`set` handlers are method names; generic ones use `info[#info]` as the profile field name.
- Prefer feature detection (`HasModern*API`) over flavor checks.
- User-visible text is `L["PPN_..."]` in both [Locales/enUS.lua](../Locales/enUS.lua) and [Locales/zhCN.lua](../Locales/zhCN.lua).
- New WoW API globals go in both `.luacheckrc` and `.luarc.json` (see [ppn-lua-globals-sync](skills/ppn-lua-globals-sync/SKILL.md)); do not silence warnings 111/112/113 instead.
- Do not edit `Libs/`, the `@project-version@` token in the `.toc`, or generated files.

## Running checks

[![CI](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/ci.yml)

[workflows/ci.yml](workflows/ci.yml) runs on every push to `master` and on every pull request, and never publishes. Jobs: StyLua `--check` (all Lua files except the generated `ChangelogManifest.lua`), Luacheck, the three test files, TOC validation plus the changelog check, and a dry-run package build that runs after the other four.

### Full pipeline (Windows)

Run directly on `master`:

```powershell
.\Tools\dev.ps1
```

Steps, in order: StyLua (**writes** formatting changes to the files), Luacheck, the three Lua test files, `Tools/validate-toc.lua`, the changelog manifest check, and a packager dry run (`-d`, nothing is uploaded; the zip lands in the gitignored `.release/`). It stops at the first failure and ends with `All local checks completed successfully.`. It refuses to run on any branch except `master`.

Do not wrap it in `powershell -NoProfile -ExecutionPolicy Bypass -File ...`. On Windows with `core.autocrlf=true`, Git may list formatted files as modified although their content is unchanged; confirm with `git diff --stat`.

### Individual checks

Run from the repository root. `lua` must be Lua 5.1 (`lua5.1`, or `C:\Program Files (x86)\Lua\5.1\lua.exe` on Windows, which is not on `PATH` by default).

| Check | Command |
|-------|---------|
| Formatting (check only, same as CI) | `stylua --check --glob "**/*.lua" --glob "!ChangelogManifest.lua" .` |
| Formatting (write) | `stylua --glob "**/*.lua" --glob "!ChangelogManifest.lua" .` |
| Lint | `.\Tools\luacheck.exe --no-color -q .` |
| Unit tests | `lua Tests/test_utils.lua`, `lua Tests/test_config.lua`, `lua Tests/test_main.lua` |
| TOC and file structure | `lua Tools/validate-toc.lua` |
| Changelog manifest is current | `lua Tools/generate-changelog-manifest.lua --check` |

Each test file prints `PASS`/`FAIL` lines and ends with `All tests passed.` or exits with status 1. There is no type checker: `.luarc.json` only configures editor diagnostics, and `Libs/` is not needed because the tests stub the libraries.

### Makefile

[Makefile](../Makefile) mirrors these checks (`make format`, `format-check`, `lint`, `test`, `validate`, `changelog`, `changelog-check`, `build`, `check`, `dev`, `clean`). `make` is not installed on the Windows machine these instructions were verified on, so the Makefile targets themselves were not run. Differences from CI and `dev.ps1`:

- Its Lua file list includes `ChangelogManifest.lua`, which CI and `dev.ps1` deliberately exclude (StyLua can change the quote style the generator emits).
- `make dev` wraps `dev.ps1` in `powershell -NoProfile -ExecutionPolicy Bypass -File`; run `.\Tools\dev.ps1` directly instead.
- `make check` runs `format-check`, `lint`, `test`, `validate` and `changelog-check`, but not `build`.

## Changelog

Edit [changelog.txt](../changelog.txt) (plain text, one entry per line; it is also the packager's release changelog), then regenerate the manifest the addon displays:

```powershell
lua Tools/generate-changelog-manifest.lua
```

Never edit `ChangelogManifest.lua` by hand. CI and `dev.ps1` fail if it is out of date.

## Git conventions

- Develop on `master`. Do not commit to `release`; see [docs/RELEASING.md](../docs/RELEASING.md).
- One logical change per commit. No message format is enforced: the history contains short descriptive sentences, `feat:`/`chore:` prefixes, version-named commits and Dependabot titles. Write a short, accurate summary of what changed.
- Version tags (`MAJOR.MINOR.PATCH`, no `v` prefix) are created by the release workflow. Do not create them by hand except to start a new minor or major series.
- Do not force-push, rewrite published history, or commit generated output, `.release/`, `Libs/` contents or executables (`*.exe` is gitignored).
- Review `git diff` before committing and do not include unrelated changes.

## Pull requests

- CI (all five jobs) must pass. The repository does not enforce this: `master` has no required status checks, reviews or pull-request requirement (verified 2026-11-13), so the check is on you.
- There is no pull request template. Describe what changed and why, and how you tested it (which commands from [Running checks](#running-checks) you ran).
- Keep the change scoped to the request; mention unrelated problems instead of fixing them.
- The bot pull request from `ci/toc-interface-update` updates TOC interface numbers and badge files; check that it only changes those before merging, or close it.
- Bug reports and feature requests use [the issue templates](ISSUE_TEMPLATE/); blank issues are disabled.

## Definition of done

- The change does what was asked and nothing else.
- New isolable logic has tests; existing tests still pass.
- User-visible text exists in both locale files.
- `.\Tools\dev.ps1` ran on `master` and ended with `All local checks completed successfully.`.
- README, `docs/` and this file are updated when behavior, commands or workflows changed.
- `git diff` was reviewed, and the changelog was updated for user-visible changes.

## Releases

[![Interface versions](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/interface-version.yml)
[![Release](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml/badge.svg)](https://github.com/Limmek/PersonalPlayerNotes/actions/workflows/release.yml)

`master` is where all development happens; `release` exists only for publishing. A push to `release` automatically bumps the patch version, tags the commit and publishes to CurseForge and GitHub, with no pull request, label or approval step. Only the owner publishes. The complete procedure, preconditions and the current state of the two branches are in [docs/RELEASING.md](../docs/RELEASING.md).

[workflows/interface-version.yml](workflows/interface-version.yml) keeps the `## Interface` numbers and the badge files in sync once a day (details in [docs/RELEASING.md](../docs/RELEASING.md#interface-versions)).

## Project structure

Code map, data model and test architecture: [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md). Top level:

- [AGENTS.md](../AGENTS.md) — mandatory rules for coding agents.
- [PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc) — addon manifest and load order.
- [PersonalPlayerNotes.lua](../PersonalPlayerNotes.lua), [PersonalPlayerNotesUtils.lua](../PersonalPlayerNotesUtils.lua), [PersonalPlayerNotesConfig.lua](../PersonalPlayerNotesConfig.lua) — the addon code.
- [Locales/](../Locales/) — AceLocale string tables (`enUS.lua`, `zhCN.lua`).
- [Tests/](../Tests/) — pure-Lua unit tests runnable outside of WoW.
- [Tools/](../Tools/) — `dev.ps1`, `validate-toc.lua`, `generate-changelog-manifest.lua`, `Install-LocalAddon.ps1`.
- [docs/](../docs/) — technical reference.
- [.github/skills/](skills/) — step-by-step agent workflows.
- [embeds.xml](../embeds.xml) / [.pkgmeta](../.pkgmeta) — Ace3 library declarations and packaging config.
- [.stylua.toml](../.stylua.toml), [.luacheckrc](../.luacheckrc), [.luarc.json](../.luarc.json) — formatter, linter and editor-diagnostics configuration.
- [changelog.txt](../changelog.txt) — release changelog; `ChangelogManifest.lua` is generated from it.
