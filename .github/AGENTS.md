# AGENTS

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
- Match the repository editor assumptions in [.vscode/settings.json](../.vscode/settings.json): Lua 5.1, WoW API stubs, and a number of intentionally disabled diagnostics.
- Pure Lua logic (no WoW API/Ace3 dependency) is unit tested with plain `lua5.1`, no WoW client required:
  - [Tests/test_utils.lua](../Tests/test_utils.lua) - legacy Shitlist key parsing, client feature detection, addon metadata getters, SavedVariables schema migration, `OpenBlizzardOptions()` routing.
  - [Tests/test_config.lua](../Tests/test_config.lua) - `PersonalPlayerNotesConfig.lua`'s AceDB defaults shape and all reasons/listed-players/alert CRUD accessors.
  - [Tests/test_main.lua](../Tests/test_main.lua) - `PersonalPlayerNotes:GetOldConfigData()`'s legacy Shitlist data migration logic.
  - [Tests/support/bootstrap.lua](../Tests/support/bootstrap.lua) - shared WoW/Ace3 stub loader used by the files above (not a test itself).
  - Run all of them with `make test`, or individually with `lua5.1 Tests/test_X.lua`. Only add tests here for genuinely isolable logic (e.g. legacy data parsing, feature detection, CRUD accessors) - don't add artificial tests for WoW-API-coupled code that can't run outside a client (menu/tooltip rendering, AceGUI widgets, minimap icon).
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