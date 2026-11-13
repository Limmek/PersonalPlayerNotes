# Releasing

Detailed reference for publishing. The mandatory rules are in [AGENTS.md](../AGENTS.md); the step-by-step agent workflow is [ppn-release-publish](../.github/skills/ppn-release-publish/SKILL.md).

## Branch model

| Branch | Purpose |
|--------|---------|
| `master` | All development. CI runs on every push and pull request. |
| `release` | Publish target only. Never edit, format, test or commit on it. |

The `release` branch is updated by pushing `master` to it, which publishes immediately. Pushing to `release` is a publishing action: do it only when the owner explicitly asks.

## What a push to `release` does

[.github/workflows/release.yml](../.github/workflows/release.yml) triggers on any push to `release` (not on a pull request). It has no label or approval step.

1. Job `Bump patch version and tag` takes the highest existing tag that matches `MAJOR.MINOR.PATCH`, increments the patch number, creates that tag on the pushed commit and pushes it. Minor and major bumps are not automated: create such a tag manually before the next push if one is needed.
2. When `Release` completes successfully, [.github/workflows/publish.yml](../.github/workflows/publish.yml) runs (`workflow_run`). It checks out the exact commit that `Release` ran on and runs the BigWigsMods packager with project ID `344967`. It uses the repository secrets `CF_API_KEY` and `GITHUB_TOKEN` (exposed to the packager as `GITHUB_OAUTH`).
3. The packager builds the zip using [.pkgmeta](../.pkgmeta), substitutes the git tag for `@project-version@`, uses [changelog.txt](../changelog.txt) as the changelog, and uploads to CurseForge and a GitHub release (a zip named `PersonalPlayerNotes-<tag>.zip` plus `release.json`).

`release.yml` also contains its own packager step without secrets. The actual release is produced by `publish.yml`; the effect of the packager step inside `release.yml` was not verified.

## Preconditions before publishing

- Everything to be released is merged and pushed on `master`, and the [CI workflow](../.github/workflows/ci.yml) on `master` is green (it runs on every push to `master` and on every pull request, but is not a required check).
- [changelog.txt](../changelog.txt) describes the release and `ChangelogManifest.lua` was regenerated from it (`lua Tools/generate-changelog-manifest.lua --check` passes).
- `PersonalPlayerNotes.toc` still has `## Version: @project-version@`.

## Publishing

The workspace task **Publish Release from master** ([.vscode/tasks.json](../.vscode/tasks.json)) runs:

```sh
git push origin master:release
```

After the push `release` points to the same commit as `master`. The task never force-pushes. If Git rejects the push as non-fast-forward, stop and ask the owner; do not force-push on your own.

Verify afterwards:

```sh
gh run list --workflow release.yml --limit 1
gh run list --workflow publish.yml --limit 1
git ls-remote --tags origin
```

## Interface versions

[.github/workflows/interface-version.yml](../.github/workflows/interface-version.yml) runs daily and on demand. It updates `## Interface` through `p3lim/toc-interface-updater` for the retail flavor, then rewrites the line to `<retail>, 16001`, preserving the WoW: Forever number. It regenerates the five files in `.github/badges/`, each ending with a trailing newline, and opens a pull request from the branch `ci/toc-interface-update` when something changed. Review and merge or close that pull request on GitHub.

## Limitations

- The local `dev.ps1` package build uses packager `v2.5.1` for `release.sh`, while the GitHub workflows use `BigWigsMods/packager@v2.7.0`.
- Branch protection (verified 2026-11-13): `master` blocks force pushes and branch deletion but does not require pull requests, reviews or status checks; `release` has no protection at all; there are no repository rulesets. Nothing technical stops a push to `release`, so the rules in [AGENTS.md](../AGENTS.md) are the only safeguard.
