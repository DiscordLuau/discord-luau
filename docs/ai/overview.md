---
title: Contributing with AI
description: The rules for pull requests written with the help of AI tools.
sidebar:
  order: 0
---

You are welcome to use AI tools (Claude, Copilot, Cursor, Codex and others) to write code for discord-luau. A pull request is judged on what it changes, not on how it was written. These pages are the rules for getting an AI-assisted change merged. They apply to every pull request, and they are written so that both you and your AI tool can follow them.

## The short version

- **You own the change.** You must understand every line you submit and be able to explain it in review. "The AI wrote it" is not an answer to a review comment.
- **Test it.** Run the checks before you open the pull request. Every bug fix comes with a test that fails without the fix. See [Testing your changes](/ai/testing).
- **Say that you used AI.** One line in the pull request description is enough, for example "Written with Claude Code; I reviewed and tested it."
- **Answer reviews yourself.** Reviewers want to talk to you, not to a model. You can use AI to help with a fix, but reply in your own words.
- **Keep it small.** One change per pull request. Small pull requests get reviewed and merged faster.
- **Talk first about big changes.** Open an issue before a new feature or a large refactor, and do not open many AI-generated pull requests at once. Maintainers may close a pull request whose author cannot explain it.
- **Follow the commit and pull request format.** See [Commits and pull requests](/ai/commits-and-pull-requests).

## Instructions for AI tools

The repository has an `AGENTS.md` file at its root. Most AI coding tools read it automatically. It holds the setup commands, the checks, where code goes and the code style. `CLAUDE.md` imports the same file for Claude Code. If your tool does not read `AGENTS.md` on its own, point it at the file before you start.

## Keep secrets out

- Never paste bot tokens, `.env.luau` contents or other private data into an AI tool, an issue or a pull request.
- Report security problems privately to a maintainer, not in a public issue or pull request.

## What not to commit

- Tokens, `.env.luau` files or anything else secret.
- Your AI tool's working files: plans, design notes, chat logs, scratch scripts. Keep them on your machine. The `docs` folder is for documentation people read on this website.
