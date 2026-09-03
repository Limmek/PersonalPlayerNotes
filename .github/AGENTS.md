# AGENTS

## Critical Guardrails (read first)

- **Never do a wholesale/regenerated rewrite of a config file.** [.vscode/settings.json](../.vscode/settings.json) and [.luacheckrc](../.luacheckrc) in particular must only be changed via small, targeted, additive edits (add the one new key/global you need). Re-typing or reconstructing the whole file from memory is how existing entries (e.g. `LoadAddOn`, `DisableAddOn`, other globals) have been accidentally dropped before. If you must touch one of these files, read it in full first, then edit the smallest possible span, then read it back to confirm nothing else changed.
- **Two separate, independent globals lists must always be kept in sync, by hand, in the same change:** `.luacheckrc`'s `read_globals`/`globals` (drives the real Luacheck CLI) and [.vscode/settings.json](../.vscode/settings.json)'s `Lua.diagnostics.globals` (drives the editor's live Lua language-server diagnostics). Neither tool reads the other's config. Adding a new WoW API global to only one of them causes either a false "undefined global" in the editor or a real Luacheck CI failure — always add to both, then verify with `get_errors` (editor) and a `.\Tools\dev.ps1` run (Luacheck) before considering the change done.
- **The only validation command to run for this repo is `.\Tools\dev.ps1`, invoked directly** (e.g. `.\Tools\dev.ps1` or `Tools/dev.ps1`), never wrapped in `powershell -NoProfile -ExecutionPolicy Bypass -File ...` or similar. Do not substitute a partial check (only luacheck, only stylua, only the lua test files) for the full pipeline when finishing a piece of work — run the whole thing and read through to the literal "All local checks completed successfully." line (or an explicit failure) before reporting success.
- **Stay strictly inside the scope of what was asked.** Do not refactor, "clean up", rename, or restructure unrelated code, add speculative error handling, add comments/docstrings to untouched code, or introduce new abstractions "just in case" while fixing a specific bug or adding a specific feature. If a fix reveals a second, unrelated issue, mention it and ask before touching it rather than silently expanding the change.
- **Don't loop on the same failing approach.** If an edit, test run, or tool call fails or produces an unexpected result twice, stop and re-read the actual current file state (don't trust your own summary of what you think you wrote) before trying a third variation. Prefer reading the real file/output over re-deriving it from memory or from a prior message.
- When editing generated/derived files (`Sounds/Manifest.lua`, anything produced by a `Tools/*.lua` generator), regenerate via the tool instead of hand-editing the output.

## Project Scope

PersonalPlayerNotes is a World of Warcraft addon written in Lua 5.1 with Ace3.

- Read [README.md](../README.md) for the user-facing addon summary.
- Treat [PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc) as the authoritative load order and metadata manifest.
- Main behavior lives in [PersonalPlayerNotes.lua](../PersonalPlayerNotes.lua), option definitions in [PersonalPlayerNotesConfig.lua](../PersonalPlayerNotesConfig.lua), and metadata/UI helpers in [PersonalPlayerNotesUtils.lua](../PersonalPlayerNotesUtils.lua).

## Working Rules

- Keep edits compatible with both Retail and Classic code paths unless the task is explicitly flavor-specific.
- Prefer feature detection over hardcoded flavor checks (`WOW_PROJECT_ID`/`IsRetail`) for anything that depends on client API surface, e.g. `PersonalPlayerNotes:HasModernMenuAPI()`, `HasModernTooltipAPI()`, `HasModernSettingsAPI()`, `HasModernAddOnAPI()`, `HasModernUIReloadAPI()` in [PersonalPlayerNotesUtils.lua](../PersonalPlayerNotesUtils.lua). Classic clients have progressively picked up modern Retail APIs, so a flavor check can silently go stale.
- When changing menu, tooltip, or player-interaction behavior, check both branches in [PersonalPlayerNotes.lua](../PersonalPlayerNotes.lua): the modern path uses `Menu.ModifyMenu` and `TooltipDataProcessor`; the legacy fallback path uses `UnitPopup_ShowMenu` hooks and `GameTooltip:HookScript`.
- Some clients don't expose the `C_AddOns`/`C_UI` namespaces yet (confirmed live on Wrath Classic) — addon load/disable/reload for the legacy Shitlist migration must keep the `LoadAddOn`/`DisableAddOn`/`ReloadUI` fallback path guarded by `HasModernAddOnAPI()`/`HasModernUIReloadAPI()`.
- Preserve the file order in [PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc): embedded libs, locales, then Lua files. If a new file is added, place it deliberately.
- Do not manually edit bundled libraries under `Libs/`. Dependency sourcing is controlled by [.pkgmeta](../.pkgmeta).
- Do not replace the `.toc` version token `@project-version@`. Versioning is injected by the packager and read at runtime via `C_AddOns.GetAddOnMetadata()`.
- Keep SavedVariables schema changes minimal and deliberate. Defaults are defined in [PersonalPlayerNotesConfig.lua](../PersonalPlayerNotesConfig.lua); profile or listed-player structure changes may require migration handling via `PersonalPlayerNotes:MigrateSavedVariablesSchema()` in [PersonalPlayerNotesUtils.lua](../PersonalPlayerNotesUtils.lua) and bumping `PersonalPlayerNotes.SCHEMA_VERSION`.
- Preserve the legacy `Shitlist` migration path unless the task explicitly updates migration behavior.

## Localization Rules

- Localization strings use AceLocale with `L["PPN_..."]` keys.
- When adding or renaming a localization key, update both [Locales/enUS.lua](../Locales/enUS.lua) and [Locales/zhCN.lua](../Locales/zhCN.lua) in the same change.
- Reuse existing naming patterns for locale keys and option labels before adding new variants.

## Validation

- Format with [StyLua](https://github.com/JohnnyMorganz/StyLua) using [.stylua.toml](../.stylua.toml) (`make format` / `make format-check`). CI fails the `format` job if a file isn't formatted — don't hand-format against the grain of what StyLua would produce.
- Preferred lint baseline is the existing luacheck configuration in [.luacheckrc](../.luacheckrc). Globals are declared explicitly (`globals`/`read_globals`), not blanket-ignored — if you introduce a genuinely new WoW API global, add it there rather than suppressing warning codes 111/112/113.
- Match the repository editor assumptions in [.vscode/settings.json](../.vscode/settings.json): Lua 5.1, WoW API stubs, and a number of intentionally disabled diagnostics. Its `Lua.diagnostics.globals` list is a separate declaration from `.luacheckrc`'s `read_globals`/`globals` — the Lua language server and luacheck don't share config, so a new WoW API global needs to be added to both or the editor will flag it as undefined even though `luacheck` is clean (and vice versa).
- Pure Lua logic (no WoW API/Ace3 dependency) is unit tested with plain `lua5.1`, no WoW client required:
  - [Tests/test_utils.lua](../Tests/test_utils.lua) - legacy Shitlist key parsing, client feature detection, addon metadata getters, SavedVariables schema migration, `OpenBlizzardOptions()` routing.
  - [Tests/test_config.lua](../Tests/test_config.lua) - `PersonalPlayerNotesConfig.lua`'s AceDB defaults shape and all reasons/listed-players/alert CRUD accessors.
  - [Tests/test_main.lua](../Tests/test_main.lua) - `PersonalPlayerNotes:GetOldConfigData()`'s legacy Shitlist data migration logic, client-flavor detection (`IsRetail`), and the decision logic behind the tooltip hook (`GameTooltip`), minimap data-broker clicks (`MiniMapIcon`), and both the modern (`DropDownMenuInitialize`) and legacy (`UnitPopup_ShowMenu`) unit-menu handlers.
  - [Tests/support/bootstrap.lua](../Tests/support/bootstrap.lua) - shared WoW/Ace3 stub loader used by the files above (not a test itself).
  - Run all of them with `make test`, or individually with `lua5.1 Tests/test_X.lua`. Only add tests here for genuinely isolable logic (e.g. legacy data parsing, feature detection, CRUD accessors) - don't add artificial tests for real Blizzard UI rendering that can't run outside a client.
  - `GameTooltip`, `MiniMapIcon`, `DropDownMenuInitialize`, and `UnitPopup_ShowMenu` look WoW-API-coupled but are written with Lua colon-method sugar (`function PersonalPlayerNotes:GameTooltip()`), and the WoW client always invokes them with the real UI object (tooltip frame, Menu rootDescription, dropdown button) as `self`/callback args rather than the addon table. That means their pure decision logic - which line/button to show, which options panel to open, whether to create/edit a listed player, whether to fire an alert - is directly callable with small fake doubles standing in for those UI objects, as seen in `test_main.lua`. The one boundary that still can't be usefully faked is `AceGUIDefaults()` (real AceGUI-3.0 widget creation), so it's stubbed out exactly like `LibStub()`-returned libraries are elsewhere in these tests; the actual Blizzard rendering behind all four hooks remains untested.
- [Tools/validate-toc.lua](../Tools/validate-toc.lua) (`make validate`) checks every `*.toc` file: required metadata fields, that `## Version` is still the `@project-version@` placeholder, plausible `## Interface*` values, that every referenced file exists, and no duplicate file entries.
- CI behavior is defined in [.github/workflows/ci.yml](workflows/ci.yml) (format/lint/tests/validate/build, never publishes), [.github/workflows/release.yml](workflows/release.yml) (tag + publish, only on a merged PR to `master`), and [.github/workflows/interface-version.yml](workflows/interface-version.yml).

## Packaging Notes

- Packaging metadata lives in [.pkgmeta](../.pkgmeta); `.github/` and `.vscode/` are intentionally excluded from packaged releases.
- The addon is packaged with BigWigsMods packager and publishes against CurseForge project `344967`.
- Keep release-related documentation concise and prefer linking to existing files instead of duplicating workflow details here. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full release/testing process.

## Useful Checks Before Editing

- Search for an existing Ace3 option, chat command, or helper before adding a parallel implementation.
- If a change touches metadata shown in the UI, confirm whether it should come from `.toc` via `GetAddOnMetadata()` rather than from a duplicated string.
- If a change adds a new source file, update [PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc) and verify any required locale or config wiring in the same edit.