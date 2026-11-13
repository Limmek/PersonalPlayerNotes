---
name: ppn-release-publish
description: 'Use only when the owner explicitly asks to publish, release, bump the version, or sync master to the release branch of PersonalPlayerNotes. A push to release immediately tags a new patch version and publishes to CurseForge and GitHub, so this skill checks preconditions and requires explicit confirmation before any push.'
disable-model-invocation: true
---

# Publish a release

A push to the `release` branch cannot be undone cleanly: it creates a version tag and uploads a public package. Never run this workflow on your own initiative, and never treat an earlier approval as approval for this push.

## When to use

- The owner says to publish, cut a release, or push `master` to `release`.
- The owner asks whether a release is ready (steps 1 to 3 only; do not push).

## Required context

- [docs/RELEASING.md](../../../docs/RELEASING.md): what the workflows do and the limitations.
- [.vscode/tasks.json](../../../.vscode/tasks.json): the task **Publish Release from master** runs `git push origin master:release`.
- [.github/workflows/release.yml](../../../.github/workflows/release.yml) and [publish.yml](../../../.github/workflows/publish.yml).

## Workflow

1. **Inspect, read-only.** Run `git status --short --branch` and `git fetch origin`.
2. **Check preconditions.**
   - The working tree has no uncommitted changes that belong in the release, and `master` is pushed (`master` equals `origin/master`).
   - The CI run for the `origin/master` commit succeeded: `gh run list --workflow ci.yml --branch master --limit 1`.
   - `changelog.txt` describes the release and `lua Tools/generate-changelog-manifest.lua --check` passes.
   - `.\Tools\dev.ps1` was run on `master` and ended with `All local checks completed successfully.` (run it only if the owner asked; it formats files in place).
3. **Report and stop.** Tell the owner what will be published and that the owner can start it with the **Publish Release from master** task.
4. **Wait for explicit confirmation** of the exact command, in this session. Do not infer it.
5. **Push only the confirmed command.** The normal command is `git push origin master:release` (or the VS Code task). If Git rejects it, stop and report; never use `--force` or `--force-with-lease` unless the owner named that exact command.
6. **Verify.** `gh run list --workflow release.yml --limit 1`, then `gh run list --workflow publish.yml --limit 1`, and `git ls-remote --tags origin`. Report the real run conclusions and the new tag. If a run fails, report it and stop; do not retry by pushing again.

## Safety

- Never commit, edit or format on `release`; it only receives pushes of `master`.
- Do not create tags by hand, delete tags or branches, or re-run workflows without being asked.
- Do not claim the release is published until `publish.yml` concluded `success` and the tag exists.
- No technical protection exists on `release` (no branch protection or rulesets), so your restraint is the only safeguard.

## Validation

The verification commands in step 6, with their real output, are the validation. Minor and major bumps are not automated; if the owner wants one, they must create the tag first.

## Completion criteria

- The owner confirmed the exact command, it ran, `release.yml` and `publish.yml` concluded `success`, and the new tag exists on origin; or
- the workflow stopped at step 3 or 4 with a clear report of what blocks publishing.
