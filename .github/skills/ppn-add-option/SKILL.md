---
name: ppn-add-option
description: 'Use when adding or changing a user-visible option, setting, label, tooltip text, locale string or stored profile field in PersonalPlayerNotes (for example a new toggle in the Settings window, a new field on reasons or listed players, or a renamed label). Covers defaults, the AceConfig options table, both locale files, tests and validation.'
---

# Add or change an option

## When to use

- A new toggle, input, dropdown or button in the Options, Reasons or Listed Players windows.
- A new field stored in `db.profile`, or a changed default.
- A new or renamed `L["PPN_..."]` string.

Do not use it for pure logic fixes with no UI or stored-data change. If the stored shape changes incompatibly, also follow [ppn-schema-migration](../ppn-schema-migration/SKILL.md).

## Required context

Read before editing:

- `PersonalPlayerNotes.defaults` and the matching group in `PersonalPlayerNotes.options` in [PersonalPlayerNotesConfig.lua](../../../PersonalPlayerNotesConfig.lua).
- The closest existing option of the same type. Reuse its pattern and, for the same kind of input, its widget.
- [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md) (data model, options and windows).
- [Locales/enUS.lua](../../../Locales/enUS.lua) and [Locales/zhCN.lua](../../../Locales/zhCN.lua) near related keys.

## Workflow

1. Run `git status` and note files that already have changes; do not touch them beyond this task.
2. Search for an existing option or helper that already does this (`grep` for the field name and for similar `L["PPN_..."]` keys).
3. Add the field to `defaults.profile` with a default value. AceDB fills missing fields from defaults, so an additive field with a default needs no migration.
4. Add the option to the correct group of `PersonalPlayerNotes.options` (`Settings`, `Reasons` or `ListedPlayers`). Use the generic handlers when they fit: `GetAlert`/`SetAlert` for `profile.alert.*` and `GetContextMenu`/`SetContextMenu` for `profile.contextMenu.*` read and write the field named by the option key (`info[#info]`), so the option key must equal the field name. Otherwise add `Get<Name>`/`Set<Name>` methods next to related ones.
5. Add every new string to both locale files in the same change, next to related keys. If you cannot provide a Chinese translation, add the English text and list the key in your report as untranslated.
6. If another window shows the value, call the existing refresh helpers (`NotifyIconOptionsChanged` pattern, `RefreshDialog(appName)`) instead of inventing new ones.
7. Add tests for isolable logic in [Tests/test_config.lua](../../../Tests/test_config.lua) (defaults shape, getter and setter behavior). Use `bootstrap.loadAddon()` and `freshProfile`.
8. If the change uses a new WoW API global, follow [ppn-lua-globals-sync](../ppn-lua-globals-sync/SKILL.md).
9. If the change is user-visible, edit `changelog.txt` and run `lua Tools/generate-changelog-manifest.lua`.
10. Update README or `docs/ARCHITECTURE.md` if the documented behavior or data model changed.

## Safety

- Do not rename or remove existing profile fields without a migration; players have saved data under those names.
- Do not change window width or height constants (`DIALOG_WIDTH_UNITS`, `MAX_DIALOG_HEIGHT`) without testing in the game client.
- Do not rewrite unrelated option groups or reformat them.

## Validation

- Locale parity: both files define the same keys. This prints keys present in only one file (empty output is the goal; note that `PPN_CONFIG_MIGRATE_OLD_DATA` is missing from zhCN already):

  ```powershell
  $k = { param($f) [regex]::Matches((Get-Content $f -Raw), 'L\["(PPN_[A-Z0-9_]+)"\]\s*=') | % { $_.Groups[1].Value } | Sort-Object -Unique }
  Compare-Object (& $k Locales\enUS.lua) (& $k Locales\zhCN.lua)
  ```

- Run the relevant single test file while iterating, for example `lua Tests/test_config.lua`.
- Finish with the full pipeline on `master`: `.\Tools\dev.ps1` through to `All local checks completed successfully.`.
- Review `git diff` for unrelated changes.

## Completion criteria

- The option works through its handlers, has a default, and exists in both locale files (or the untranslated keys are reported).
- New logic has passing tests; the full pipeline passed or the gap is reported.
- Changelog and docs are updated where behavior changed.
- The final diff contains only this feature.
