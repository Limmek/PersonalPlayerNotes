---
name: ppn-schema-migration
description: 'Use when the stored shape of db.profile changes in PersonalPlayerNotes: renaming, removing, retyping or restructuring a SavedVariables field, or changing how existing saved values are interpreted. Covers bumping SCHEMA_VERSION, writing the migration step in MigrateSavedVariablesSchema, tests and validation. Not needed for a purely additive field that has a default.'
---

# Change the SavedVariables schema

## When to use

- A field in `db.profile` is renamed, removed, retyped or restructured.
- The meaning of an existing saved value changes (version 2 changed `alert.sound` from a number to a filename).
- Existing users' data must be converted at login.

Not needed when you only add a new field with a default: AceDB fills missing fields from `PersonalPlayerNotes.defaults` automatically. Add the field through [ppn-add-option](../ppn-add-option/SKILL.md) instead.

## Required context

- `PersonalPlayerNotes.SCHEMA_VERSION` and `MigrateSavedVariablesSchema()` in [PersonalPlayerNotesUtils.lua](../../../PersonalPlayerNotesUtils.lua).
- `PersonalPlayerNotes.defaults` in [PersonalPlayerNotesConfig.lua](../../../PersonalPlayerNotesConfig.lua).
- The existing migration tests in [Tests/test_utils.lua](../../../Tests/test_utils.lua) (search for `MigrateSavedVariablesSchema`).
- [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md), section "Schema migration".

## Workflow

1. Run `git status`; preserve other changes.
2. Describe the old shape and the new shape in one sentence each. Confirm the old shape from the current code and existing tests, not from memory.
3. Bump `PersonalPlayerNotes.SCHEMA_VERSION` by exactly one.
4. In `MigrateSavedVariablesSchema()` add a new `if fromVersion < N then ... end` block after the existing ones, where `N` is the new version. Keep earlier blocks unchanged. The function ends by writing `profile.schemaVersion = PersonalPlayerNotes.SCHEMA_VERSION`.
5. Write the migration against `self.db.profile` only. Use literal fallback values. Never reference `PersonalPlayerNotes.defaults` inside the migration: `Tests/test_utils.lua` loads the Utils file in isolation, where `defaults` is nil, and the call would error.
6. Update `PersonalPlayerNotes.defaults` to the new shape.
7. Update all code that reads the old field, found with a search for the field name across the `.lua` files and `Tests/`.
8. Add tests in `Tests/test_utils.lua`: an old-shape profile gets converted, an already-current profile is left untouched, and a fresh profile (`schemaVersion = nil`) ends at the current version. Mirror the existing fixtures: assign `PersonalPlayerNotes.db = { profile = { ... } }` and call `PersonalPlayerNotes:MigrateSavedVariablesSchema()`.
9. Document the new version in `docs/ARCHITECTURE.md` (the `schemaVersion` row and the migration note).
10. Add a changelog line if users can notice the change.

## Safety

- Never delete user data unless the old field is provably unused and replaced by the new one in the same migration.
- Do not edit or drop a previous migration block; users upgrading from older versions still run it.
- A migration runs once per login before the options are registered: keep it fast, free of WoW API calls and free of side effects outside `db.profile`.
- The migration cannot be tested against a real game client here; say so in your report.

## Validation

- `lua Tests/test_utils.lua` prints `All tests passed.`; also run `lua Tests/test_config.lua` and `lua Tests/test_main.lua`, because defaults changed.
- Finish with the full pipeline on `master`: `.\Tools\dev.ps1`.
- Review `git diff`: `SCHEMA_VERSION` changed by one, one new migration block, defaults and readers updated, nothing else.

## Completion criteria

- `SCHEMA_VERSION` is bumped and the migration converts an old profile correctly (proved by a test).
- Current-version and fresh profiles are unaffected (proved by tests).
- All readers use the new shape; docs describe it.
- The full pipeline passed, or the gap is reported.
