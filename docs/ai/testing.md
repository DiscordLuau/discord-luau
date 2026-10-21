---
title: Testing your changes
description: How to test a change before you open a pull request, and how to write tests for fixes.
sidebar:
  order: 1
---

Every pull request runs the same checks in CI. Run them yourself first, so the pull request is green before anyone reviews it.

## Run the checks

You need [pesde](https://pesde.dev) and [Rokit](https://github.com/rojo-rbx/rokit) installed (see [Environment Setup](/getting-started/environment)). Then, from the repository root:

```sh
rokit install                      # installs the pinned tools; Rokit asks once before installing a tool it has not seen, answer yes
zune setup                         # writes the Zune type definitions
zune run .zune/bundle.luau         # builds the api_types bundle
pesde install                      # installs package dependencies
```

Then run the checks in the order CI runs them:

```sh
zune run .zune/fmt.luau            # formatting (StyLua)
zune run .zune/lint.luau           # linting (Selene)
zune run .zune/analyze.luau        # type checking (luau-lsp)
zune run .zune/test.luau           # every test
```

To test only the packages you changed, pass the package folder:

```sh
zune run .zune/test.luau packages/websocket
```

Some packages (`dave`, `opus`, `sodium`) need FFI, which lets Luau call native libraries. Zune has it, and the first test run downloads the library for your platform. On a runtime without FFI, their native tests show as skipped rather than failed. If you write a test that calls a native library, copy the start of `packages/dave/tests/session.spec.luau`: it fails loudly if the library cannot load, and skips the suite when FFI is missing. Do not call the library at the top of the file, because an error there stops the whole test run. When your pull request touches these packages, CI also runs their tests on Windows and macOS.

## Every fix comes with a test

When you fix a bug, write a test that fails without your fix and passes with it.

1. Write the test first and run it. It should fail, and fail for the reason the bug describes.
2. Make the fix.
3. Run the test again. It should pass.
4. Put both results in the pull request description.

A test that passes before the fix proves nothing. It is the most common mistake in AI-written tests, so check it.

## Every feature comes with tests

New behaviour needs tests that show it working, including the error cases. Changing behaviour means updating the tests that describe it.

## Where tests go

- Tests live in `packages/<name>/tests/` and end in `.spec.luau`. They use [frktest](https://github.com/itsfrank/frktest).
- Split tests by what they cover: several small files, not one large one. For example, `packages/websocket/tests` has `reconnect.spec.luau`, `resume.spec.luau` and `stayDown.spec.luau`.
- Do not write your own fake Discord. For anything that talks to the gateway or the REST API, use `packages/discord_stub`, a local Discord that runs on your machine. Its virtual clock runs 100 times faster than real time, so a test can wait through reconnect delays and heartbeats in a fraction of a second. If it is missing something your test needs, add it to the stub (with its own tests) instead of writing a fake in your test folder.
- Do not add `tests/support` or `tests/helpers` folders. Shared test helpers belong in `discord_stub`.
