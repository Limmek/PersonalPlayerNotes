# Architecture

Detailed technical reference. The mandatory rules are in [AGENTS.md](../AGENTS.md). Everything here was verified against the source on 2026-11-13; if code and this file disagree, the code is right and this file needs fixing.

## Overview

A single WoW addon, `PersonalPlayerNotes`, written in Lua 5.1 on top of Ace3. There is no server, network access, authentication, database or build step beyond packaging.

| Concern | Implementation |
|---------|----------------|
| Addon object | `LibStub("AceAddon-3.0"):NewAddon` with AceConsole, AceEvent, AceHook, AceTimer, AceSerializer |
| Storage | AceDB-3.0 on the SavedVariables `PersonalPlayerNotesDB`, using a shared default profile |
| Options UI | AceConfig-3.0 options tables, shown through the Blizzard Settings panel and through addon-owned AceGUI frames |
| Localization | AceLocale-3.0, `enUS` (default) and `zhCN` |
| Minimap button | LibDataBroker-1.1 and LibDBIcon-1.0 |

## Load order

[PersonalPlayerNotes.toc](../PersonalPlayerNotes.toc) is authoritative:

1. `embeds.xml` — Ace3 libraries (fetched by the packager into `Libs/`; `Libs/` is gitignored and empty in a fresh checkout).
2. `Locales\Locales.xml` — `enUS.lua`, `zhCN.lua`.
3. `PersonalPlayerNotes.lua` — creates the global `PersonalPlayerNotes` addon object; lifecycle, menus, tooltip.
4. `ChangelogManifest.lua` — generated; sets `PersonalPlayerNotes.Changelog`.
5. `PersonalPlayerNotesUtils.lua` — feature detection, metadata getters, migration, dialog helpers, `Print`.
6. `PersonalPlayerNotesConfig.lua` — `PersonalPlayerNotes.defaults`, `PersonalPlayerNotes.options`, accessors.

Each file starts with `local personalPlayerNotes = ...` (the addon folder name passed in by the client).

## Where functionality belongs

| File | Responsibility |
|------|----------------|
| [PersonalPlayerNotes.lua](../PersonalPlayerNotes.lua) | `OnInitialize`, `OnEnable`, `OnDisable`, `LoadConfig`; slash commands; Shitlist migration (`GetOldConfigData`); unit context menus (`DropDownMenuInitialize`, `UnitPopup_ShowMenu`); tooltip lines and alerts (`GameTooltip`, `AlertDelayTimer`); minimap button (`MiniMapIcon`); `IsRetail`, `IsWoWForever` |
| [PersonalPlayerNotesUtils.lua](../PersonalPlayerNotesUtils.lua) | `HasModern*API` feature detection, `IsSecretUnit`, `OpenBlizzardOptions`, `ParseLegacyPlayerKey`, `SCHEMA_VERSION` and `MigrateSavedVariablesSchema`, `.toc` metadata getters, dialog sizing and `OpenDialog`/`CloseAllDialogs`/`RefreshDialog`, `Print`/`PrintDebug` |
| [PersonalPlayerNotesConfig.lua](../PersonalPlayerNotesConfig.lua) | `defaults`, `options` (`Info`, `Settings`, `Reasons`, `ListedPlayers`), every `Get*`/`Set*` accessor, sound and icon management, the icon picker |
| [Locales/](../Locales/) | All user-visible strings as `L["PPN_..."]` |
| [ChangelogManifest.lua](../ChangelogManifest.lua) | Generated from [changelog.txt](../changelog.txt); do not edit |

## Lifecycle

- `OnInitialize` — create the AceDB, register DB callbacks (`OnNewProfile`, `OnProfileChanged`, `OnProfileCopied`, `OnProfileReset` call `LoadConfig`), run `MigrateSavedVariablesSchema`, register the options tables and Blizzard categories, create the minimap icon, register slash commands, try to load the old `Shitlist` addon and migrate its data, then `LoadConfig`.
- `OnEnable` — print the banner, then hook the unit menu and tooltip using feature detection:
  - modern menus (`Menu.ModifyMenu`) → `DropDownMenuInitialize`; otherwise, if `UnitPopup_ShowMenu` exists, `SecureHook` it; otherwise print a debug message;
  - modern tooltips (`TooltipDataProcessor.AddTooltipPostCall`) → unit post call; otherwise `GameTooltip:HookScript("OnTooltipSetUnit")`.
- `LoadConfig` — clears `alert.last` and shows or hides the minimap icon. Called on profile events and when a minimap setting changes.

## Slash commands

Registered in `OnInitialize`:

| Command | Effect |
|---------|--------|
| `/ppn`, `/ppnc`, `/ppnchangelog` | `OpenBlizzardOptions()` (the changelog is an inline panel on the Info page) |
| `/ppno`, `/ppnoptions` | Options window (registered through `AceConfig:RegisterOptionsTable`) |
| `/ppnr`, `/ppnreasons` | Reasons window |
| `/ppnp`, `/ppnplayers` | Listed players window |
| `/ppnm`, `/ppnminimap` | `ToggleMiniMapIcon` |
| `/ppndebug` | `ToggleDebug` |

## Data model

Defaults are `PersonalPlayerNotes.defaults.profile` in `PersonalPlayerNotesConfig.lua`:

| Field | Meaning |
|-------|---------|
| `schemaVersion` | Stored schema version (`PersonalPlayerNotes.SCHEMA_VERSION`, currently `2`) |
| `icon`, `minimap` | Minimap button icon path and `{ hide, minimapPos }` |
| `debug` | Debug output on or off |
| `contextMenu` | `{ party, friends, chat }` — where the Add/Edit menu entry appears |
| `alert` | `{ enabled, delay, sessionOnly, sound, customSounds, newCustomSound, last }` |
| `customIcons`, `newCustomIcon`, `customIconSelected` | User-added icon filenames and their input/selection state |
| `reasons` | Array of `{ id, reason, color, alert, sound?, icon? }`; entry 1 is the protected default "None" |
| `listedPlayers` | Array of `{ id, name, realm, reason, description, color, alert, sound?, icon? }` |
| `reason`, `listedPlayer` | Scratch "mirror" objects holding the entry currently selected in the options UI |

Notes that are easy to get wrong:

- The `reason` and `listedPlayer` mirrors are copied onto the stored entry by the setters. `SetListedPlayerRealm`/`SetListedPlayerName` copy every mirror field, so a test or caller must populate the whole mirror first.
- `alert.last` and `alert.newCustomSound`-style fields are runtime or input state stored in the profile.
- A player is identified by the exact `name` and `realm` strings. On WoW: Forever the two input fields are labelled First Name and Last Name instead of Player Name and Realm (`IsWoWForever`); the stored fields stay `name` and `realm`.

### Alert behavior

`GameTooltip` plays at most one sound per sighting. An alert fires when `alert.enabled` and (`reason.alert` or `listedPlayer.alert`) and the player has no active cooldown in `alert.last`. With `sessionOnly` the player alerts once until `LoadConfig` clears `alert.last`; otherwise a timer (`AlertDelayTimer`) clears the cooldown after `alert.delay` seconds. Sound priority: `listedPlayer.sound` > `reason.sound` > `alert.sound`; if the player's own alert is off, the player's sound is ignored. A sound value is a filename in `Sounds/`, `"__inherit__"` is the dropdown placeholder for `nil`, and shipped sounds are listed in `PersonalPlayerNotes.SoundManifest` (currently only `default.mp3`).

### Schema migration

`MigrateSavedVariablesSchema` runs once per login after the DB is created. Version 2 replaced the numeric `alert.sound` with a filename. See [ppn-schema-migration](../.github/skills/ppn-schema-migration/SKILL.md) before changing the stored shape. The migration code must not reference `PersonalPlayerNotes.defaults`, because `Tests/test_utils.lua` loads the Utils file alone.

## Options and windows

`PersonalPlayerNotes.options` holds four AceConfig tables: `Info` (commands, about, changelog), `Settings` (minimap, context menu, alert, icons), `Reasons` and `ListedPlayers`. Option `get`/`set` handlers are method names on the addon; generic handlers such as `GetAlert`, `GetContextMenu` use `info[#info]` (the option's key) as the profile field name, so a new option needs a defaults entry and an option table entry with the same key.

The addon opens `Settings`, `Reasons` and `Listed_Players` in its own AceGUI frames (`AceGUIDefaults`, `OpenDialog`) instead of letting AceConfigDialog create bare frames. Window widths come from `DIALOG_WIDTH_UNITS`; heights are fitted to content (`ResizeDialogToContent`). These values were tuned in game; do not change them without testing in a client.

## Client compatibility

Capabilities are detected, not inferred from the flavor: `HasModernMenuAPI`, `HasModernTooltipAPI`, `HasModernSettingsAPI`, `HasModernAddOnAPI`, `HasModernUIReloadAPI`. `IsSecretUnit` skips secret-value units (Patch 12.0) before any unit API is called. The modern menu path registers the tags `MENU_UNIT_PLAYER`, `MENU_UNIT_ENEMY_PLAYER`, `MENU_UNIT_PARTY`, `MENU_UNIT_RAID_PLAYER`, `MENU_UNIT_FRIEND`, `MENU_UNIT_FRIEND_OFFLINE` and `MENU_UNIT_CHAT_ROSTER`; the legacy path hooks `UnitPopup_ShowMenu` and treats the friends and chat toggles as one.

Supported interface numbers are in the TOC (`## Interface: 120105, 16001`, plus Vanilla, TBC and Mists lines). `16001` is WoW: Forever and is preserved by the interface-version workflow.

## Test architecture

Tests are plain Lua 5.1 run from the repository root; there is no framework and no WoW client.

| File | Covers |
|------|--------|
| [Tests/test_utils.lua](../Tests/test_utils.lua) | `PersonalPlayerNotesUtils.lua` loaded on its own (feature detection, metadata getters, schema migration, `OpenBlizzardOptions`, `Print`) |
| [Tests/test_config.lua](../Tests/test_config.lua) | Defaults shape and all reasons, listed players, alert, sound and icon accessors; WoW: Forever labels |
| [Tests/test_main.lua](../Tests/test_main.lua) | `GetOldConfigData`, the tooltip hook, minimap clicks, both unit-menu handlers, `IsRetail` |
| [Tests/support/bootstrap.lua](../Tests/support/bootstrap.lua) | Not a test: `loadAddon()` loads the three addon files in TOC order against stubbed `LibStub`, `C_AddOns`, `tinsert`, `tremove` |

The handlers `GameTooltip`, `MiniMapIcon`, `DropDownMenuInitialize` and `UnitPopup_ShowMenu` are exercised with small fake UI objects, because the client calls them with the real UI object as `self`. The real Blizzard rendering and real AceGUI widget creation (`AceGUIDefaults`, stubbed in the tests) are not tested. Add tests only for isolable logic.

`.luacheckrc` scopes the globals the tests mutate to `files["Tests/"]`; add test-only globals there, not to the project-wide lists.

## Tooling

| Tool | Role |
|------|------|
| [Tools/dev.ps1](../Tools/dev.ps1) | Windows pipeline: StyLua (writes), Luacheck, tests, TOC validation, changelog check, packager dry run. Refuses to run outside `master`. |
| [Tools/validate-toc.lua](../Tools/validate-toc.lua) | Required TOC fields, `@project-version@` placeholder, plausible interface numbers, referenced files exist, no duplicates |
| [Tools/generate-changelog-manifest.lua](../Tools/generate-changelog-manifest.lua) | Writes or (`--check`) verifies `ChangelogManifest.lua` |
| [Tools/Install-LocalAddon.ps1](../Tools/Install-LocalAddon.ps1) | Links the checkout into WoW AddOns folders and fetches `Libs/` (uses `git svn`/`git clone`) |
| [Makefile](../Makefile) | Same checks for environments with `make`; not available on the verified Windows machine |

## Packaging

[.pkgmeta](../.pkgmeta) sets `package-as: PersonalPlayerNotes`, uses `changelog.txt` as a plain-text manual changelog, lists the Ace3 externals and excludes dev files (`.github`, `.vscode`, `Tests`, `Tools`, `Makefile`, `docs`, `AGENTS.md`, screenshots). The packager substitutes the git tag for `@project-version@`. For publishing, see [RELEASING.md](RELEASING.md).
