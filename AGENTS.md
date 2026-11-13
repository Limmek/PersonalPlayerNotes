# AGENTS

Authoritative, always-on rules for AI coding agents in this repository. Every rule has exactly one home:

| Topic | Authoritative file |
|-------|--------------------|
| Mandatory agent rules, prohibitions, validation | this file |
| Human development workflow, setup, conventions, PR requirements | [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md) |
| Code map, data model, lifecycle, test architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Release and publishing procedure | [docs/RELEASING.md](docs/RELEASING.md) |
| Step-by-step task workflows | [.github/skills/](.github/skills/) |
| User-facing addon description | [README.md](README.md) |

## Project

PersonalPlayerNotes is a World of Warcraft addon (Lua 5.1, Ace3). It stores private notes and color-coded reasons about players, shows them in the unit tooltip, and can play alert sounds. It supports Retail, WoW: Forever, Classic Era, TBC Anniversary and Mists Classic (see [PersonalPlayerNotes.toc](PersonalPlayerNotes.toc)).

Everything is local: data lives in the `PersonalPlayerNotesDB` SavedVariables. There is no server, network access, authentication or database.

Tooling: StyLua 2.5.2, Luacheck, plain `lua5.1` unit tests, BigWigsMods packager, GitHub Actions. Ace3 libraries are fetched by the packager and are not committed.

## Mandatory practices

1. Inspect the existing implementation before modifying code. Read the whole function, find all of its callers and read its tests.
2. Never invent functions, WoW APIs, SavedVariables fields, locale keys, dependencies or configuration. Verify each one exists in this repository first. If a WoW API cannot be verified, say so instead of guessing.
3. Never assume something exists; check it.
4. Do not rewrite working functionality unnecessarily.
5. Do not introduce unrelated changes: no refactors, renames, formatting sweeps, speculative error handling or extra comments outside the request. If you find a second problem, report it and ask before touching it.
6. Do not remove existing functionality without justification and authorization. The legacy Shitlist migration path must be preserved.
7. Do not change the architecture (load order, lifecycle, data shape) without understanding and stating the consequences.
8. Do not add dependencies or tools without a clear technical reason and the owner's approval.
9. Never expose secrets. `CF_API_KEY` and `GITHUB_TOKEN` exist only as GitHub repository secrets.
10. Never claim a check passed unless it ran in this session and succeeded. Quote the real result line.
11. Inspect related files (tests, locales, option tables, TOC) before implementing.
12. Review the complete `git diff` before finishing.
13. Run the relevant validation (see [Validation](#validation)).
14. Report failures and unverified assumptions explicitly.
15. Preserve existing user changes. Check `git status` first and never revert, stash, reset or overwrite files you did not change.
16. If an edit, test run or tool call fails twice, stop and re-read the real current file state before a third attempt.

When information is missing, investigate first. When uncertainty remains, say so.

## Prohibited actions

- Do not commit, push, merge, tag, force-push, delete branches, or close/merge pull requests unless the user explicitly asks for that specific action in the current request. Earlier approval does not carry over.
- The `release` branch exists only for publishing. Never edit, format, test or commit on it. Every push to `release` creates a new version tag and publishes to CurseForge and GitHub (see [docs/RELEASING.md](docs/RELEASING.md)).
- Run `Tools/dev.ps1` only on `master`. The script refuses to run on any other branch.
- Do not run `Tools/Install-LocalAddon.ps1` unless asked: it creates junctions inside the World of Warcraft AddOns folders and downloads libraries.
- Do not create temporary or helper files outside the repository (for example in `%TEMP%`). Use a gitignored path such as `.release/` and delete the files afterwards.
- Do not edit `Libs/` or replace the `@project-version@` token in the `.toc`.
- Do not hand-edit generated files (`ChangelogManifest.lua`).

## Repository rules

**Branches.** `master` is where all development happens. `release` is a publish target, updated only by the owner (see [docs/RELEASING.md](docs/RELEASING.md)).

**Client compatibility.** Prefer feature detection over flavor checks: `HasModernMenuAPI()`, `HasModernTooltipAPI()`, `HasModernSettingsAPI()`, `HasModernAddOnAPI()`, `HasModernUIReloadAPI()` and `IsSecretUnit()` in [PersonalPlayerNotesUtils.lua](PersonalPlayerNotesUtils.lua). Keep the `LoadAddOn`/`DisableAddOn`/`ReloadUI` fallbacks guarded by those helpers. `IsRetail` (from `WOW_PROJECT_ID`) and `IsWoWForever` (interface version `16001`, used only to relabel the listed-player name/realm fields) already exist; do not add further flavor branches without a reason. When changing menus or tooltips, keep both the modern path (`Menu.ModifyMenu`, `TooltipDataProcessor`) and the legacy path (`UnitPopup_ShowMenu` hook, `OnTooltipSetUnit`) working.

**Load order and metadata.** [PersonalPlayerNotes.toc](PersonalPlayerNotes.toc) is authoritative: `embeds.xml`, `Locales\Locales.xml`, then the Lua files. Add new files deliberately and update the TOC. Metadata shown in the UI (version, author, notes) comes from the `.toc` through `C_AddOns.GetAddOnMetadata()` (the getters in `PersonalPlayerNotesUtils.lua`); do not duplicate it as a string. The `## Interface` numbers are maintained by the interface-version workflow, which preserves the WoW: Forever value `16001`.

**Reuse before adding.** Search for an existing option, chat command, helper or UI pattern before writing a parallel one, and reuse the existing control for the same kind of input instead of adding a second one.

**Localization.** All user-visible text uses `L["PPN_..."]`. Add or rename a key in both [Locales/enUS.lua](Locales/enUS.lua) and [Locales/zhCN.lua](Locales/zhCN.lua) in the same change. enUS is the default locale, so a key missing from zhCN falls back to English instead of erroring; if you cannot provide a Chinese translation, say so in your report rather than silently copying English.

**Lua globals.** `.luacheckrc` (`globals`/`read_globals`) and `.luarc.json` (`diagnostics.globals`) are separate lists that must stay in sync. A new WoW global goes in both, as a small additive edit; do not suppress warning codes 111/112/113 instead. Follow [.github/skills/ppn-lua-globals-sync/SKILL.md](.github/skills/ppn-lua-globals-sync/SKILL.md). Never rewrite `.luacheckrc`, `.luarc.json` or `.vscode/settings.json` wholesale.

**SavedVariables.** Defaults live in [PersonalPlayerNotesConfig.lua](PersonalPlayerNotesConfig.lua). Changing the stored shape requires a schema bump and migration; follow [.github/skills/ppn-schema-migration/SKILL.md](.github/skills/ppn-schema-migration/SKILL.md).

**Options and settings.** Follow [.github/skills/ppn-add-option/SKILL.md](.github/skills/ppn-add-option/SKILL.md) for any user-visible option, label or stored field.

**Changelog.** Edit only [changelog.txt](changelog.txt), then regenerate `ChangelogManifest.lua` with `lua Tools/generate-changelog-manifest.lua`. `dev.ps1` and CI verify it with `--check`.

**Line endings.** Lua files and the Git index use LF; on Windows (`core.autocrlf=true`) the working copy of Markdown, `.pkgmeta` and `Makefile` is CRLF. After editing a CRLF file, confirm the endings are not mixed (`git diff --check`, `git ls-files --eol <file>`).

## Task workflows

- **Feature:** locate the owning file ([docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)), read the existing pattern next to where the code goes, implement the smallest change, add tests for isolable logic, update locales and docs, validate.
- **Bug fix:** reproduce or locate the fault from the code and the existing tests first, add a regression test that fails before the fix when the logic is testable, fix only the cause, validate.
- **Refactor:** only when asked. Behavior must not change; the tests must pass unchanged.
- **Tests:** plain Lua 5.1 in [Tests/](Tests/), run from the repository root. Test isolable logic only; Blizzard UI rendering cannot be tested outside the client (details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#test-architecture)).

## Validation

The only validation command for this repository is the full pipeline, run directly on `master`:

```powershell
.\Tools\dev.ps1
```

- Do not wrap it in `powershell -NoProfile -ExecutionPolicy Bypass -File ...`.
- It formats Lua files in place with StyLua (intended: it keeps formatting consistent), runs Luacheck, the three test files, TOC validation and the changelog check, then a dry-run package build. Read the output through to `All local checks completed successfully.` or an explicit failure.
- Do not substitute a partial check when finishing a piece of work. Single test files are fine while iterating.
- It writes a small shim to the system temp folder. To keep temp files inside the repository, point `TEMP`/`TMP` at a folder under `.release/` for the run and delete it afterwards:

  ```powershell
  $t = Join-Path (Get-Location) '.release\tmp'; New-Item -ItemType Directory -Force $t | Out-Null
  $env:TEMP = $t; $env:TMP = $t
  try { .\Tools\dev.ps1 } finally { Remove-Item $t -Recurse -Force }
  ```

- On Windows with `core.autocrlf=true`, Git can list files as modified after the run although their content is unchanged. Check `git diff --stat` and `git diff --exit-code` instead of trusting `git status`.
- If the pipeline cannot run (missing StyLua, Luacheck, Lua 5.1, Git Bash, `svn`, or both `zip` and 7-Zip, or no network), run the raw checks from [.github/CONTRIBUTING.md](.github/CONTRIBUTING.md#running-checks) and state that `dev.ps1` was not run.

Definition of done: the request is implemented without unrelated changes, tests cover new isolable logic, the full pipeline passed (or the gap is reported), documentation is updated, and the final `git diff` was reviewed.

## Documentation maintenance

- A behavior change updates the matching document in the same change: README (user-facing), `docs/ARCHITECTURE.md` (code map, data model), `docs/RELEASING.md` (workflows), `.github/CONTRIBUTING.md` (commands, conventions).
- Do not duplicate a rule in a second file; link to its home above.
- Every command, path and link you add must be verified against the repository.
- Skills live in `.github/skills/<name>/SKILL.md`; the folder name must equal the `name` field. `.github/`, `docs/` and this file are excluded from the packaged addon by [.pkgmeta](.pkgmeta).

## Skills

| Skill | Use when |
|-------|----------|
| [ppn-add-option](.github/skills/ppn-add-option/SKILL.md) | Adding or changing a user-visible option, label, locale string or stored field |
| [ppn-lua-globals-sync](.github/skills/ppn-lua-globals-sync/SKILL.md) | Luacheck or the editor reports an undefined global, or a new WoW API global is needed |
| [ppn-schema-migration](.github/skills/ppn-schema-migration/SKILL.md) | The shape of `db.profile` changes |
| [ppn-release-publish](.github/skills/ppn-release-publish/SKILL.md) | Publishing, version bumps, or syncing `master` to `release` |
