---
title: Commits and pull requests
description: How to write commits, changelog entries and pull requests for discord-luau.
sidebar:
  order: 2
---

## Commits

Commits follow [Conventional Commits](https://www.conventionalcommits.org/), with the package folder as the scope:

```text
fix(websocket): reconnect after a failed resume
feat(classes): expose guildId on Message
docs(rest): add changelog entry for baseUrl
test(websocket): cover op 9 during a reconnect
```

- **Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `chore`.
- **Scope:** the folder under `packages/`, in lowercase. Separate several packages with commas (`docs(rest,state): ...`). Leave it out for changes outside a package (`chore: update pesde lockfiles`).
- **Summary:** short, lowercase, present tense, no full stop at the end.
- **One change per commit.** If a file holds two unrelated changes, commit them separately (`git add -p` helps).
- **AI attribution is welcome.** You may credit the AI tool you used with a `Co-Authored-By` trailer, for example `Co-Authored-By: Claude <noreply@anthropic.com>`. It does not replace the one-line note in the pull request description.

## Changelogs

Every package has a `CHANGELOG.md` in the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

- For each package you change, add one line per user-visible change under `## [Unreleased]`, in a `### Added`, `### Changed` or `### Fixed` section.
- Write the line for someone using the package: what changed for them, not how the code changed.
- Do not change package versions or move entries under a version heading. Maintainers do that when they release.

## Pull requests

New pull requests open with the repository's template. Fill in every section:

1. **Pull request type:** bug fix, feature or other.
2. **What is the current behavior?** What happens today, with a link to the issue if there is one.
3. **What is the new behavior?** What your change does.
4. **Other information:** how you tested it (the commands you ran and what they printed; for a fix, the test failing before the fix and passing after) and one line on AI use, for example "Written with Copilot; I reviewed every change."

Before you ask for review:

- The checks in [Testing your changes](/ai/testing) pass.
- The diff contains only your change: no unrelated formatting, no lockfile churn you did not need, no leftover debug output.
- You have read the whole diff yourself.

## Ask first

Open an issue or ask a maintainer before you:

- Add, remove or upgrade a dependency.
- Change anything under `.github/` (CI and release workflows) or the `.zune` task scripts.
- Change a public API in a way that breaks existing bots.
- Change the license or copyright text.
