---
name: ppn-lua-globals-sync
description: 'Use when Luacheck or the editor reports an undefined or unused global in PersonalPlayerNotes, or when new code calls a WoW API global that is not yet declared. Keeps .luacheckrc (globals, read_globals) and .luarc.json (diagnostics.globals) in sync with small additive edits.'
---

# Keep Lua globals in sync

## When to use

- `luacheck` reports `accessing undefined variable 'X'` or `setting non-standard global variable 'X'`.
- The editor underlines a WoW API name that Luacheck accepts, or the other way round.
- You are about to use a WoW client API that no file declares yet.

## Required context

Two independent declarations exist. Neither tool reads the other's file:

| File | Driven tool | Section |
|------|-------------|---------|
| [.luacheckrc](../../../.luacheckrc) | Luacheck CLI and CI | `globals` (names the addon assigns to) and `read_globals` (names it only reads) |
| [.luarc.json](../../../.luarc.json) | Lua language server in the editor | `diagnostics.globals` |

[.vscode/settings.json](../../../.vscode/settings.json) holds editor settings, not the live globals list.

## Workflow

1. Run `git status`. Confirm the name is a real client API (check how other code or Blizzard documentation uses it); never add a guessed name.
2. Prefer an existing declared helper or `_G.Name` access over a new global when the code only probes for existence (see how `IsWoWForever` uses `_G.GetBuildInfo`).
3. Read the whole target file first.
4. Add the name to `.luacheckrc`: in `read_globals` when the addon only reads it, in `globals` when it assigns to it. Insert it next to related names, as the smallest possible edit.
5. Add the same name to `.luarc.json` `diagnostics.globals`, again as one added line.
6. Test-only globals that the tests mutate go in `files["Tests/"].globals` in `.luacheckrc`, not in the project-wide lists.
7. Read both files back and confirm only the intended line changed (`git diff -- .luacheckrc .luarc.json`).
8. Do not add warning codes to `ignore` and do not suppress 111/112/113 as a shortcut.

## Safety

- Never rewrite or re-type either file wholesale; earlier rewrites silently dropped existing entries.
- Keep the JSON valid (commas, quotes). Check `.luarc.json` after the edit.

## Validation

- Luacheck: `.\Tools\luacheck.exe --no-color -q .` must report `0 warnings / 0 errors`.
- Editor: check the edited source file for diagnostics.
- Parity of the two lists. `debug`, `dofile`, `files`, `io`, `loadfile` and `os` are currently only in `.luarc.json` (Luacheck's `std = "lua51"` already provides the Lua standard names, and `files` is a Luacheck config key); verified on 2026-11-13. Any other difference is a mistake. Parity script:

  ```powershell
  $rc = Get-Content .luacheckrc -Raw
  $a = [regex]::Matches(([regex]::Match($rc,'(?s)read_globals\s*=\s*\{(.*?)\n\}').Groups[1].Value + [regex]::Match($rc,'(?s)\nglobals\s*=\s*\{(.*?)\n\}').Groups[1].Value), '"([A-Za-z_0-9]+)"') | % { $_.Groups[1].Value } | Sort-Object -Unique
  $b = (Get-Content .luarc.json -Raw | ConvertFrom-Json).diagnostics.globals | Sort-Object -Unique
  Compare-Object $a $b
  ```

- Finish with the full pipeline on `master`: `.\Tools\dev.ps1`.

## Completion criteria

- The name appears in both lists (or only in `.luarc.json` if it is one of the Lua standard names listed above).
- Luacheck is clean and the diff shows exactly the added lines.
