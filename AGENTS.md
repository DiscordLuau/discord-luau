# discord-luau

A Luau library for the Discord API, split into packages under `packages/<name>/` and managed with pesde. It runs on Zune, Lune, Lute, Eryx and Roblox; everything runtime-specific goes through `packages/std_polyfills`. The rules for AI-assisted pull requests are in `docs/ai/` (overview, testing, commits and pull requests); read them before you open one.

## Setup

Install [pesde](https://pesde.dev) 0.7.4 or newer and [Rokit](https://github.com/rojo-rbx/rokit) first; pesde is not in `rokit.toml`. Older pesde fails to apply dependency patches on Windows when Git's `core.autocrlf` is on.

```sh
rokit install                 # pinned tools from rokit.toml; Rokit asks once before installing a tool it has not seen, answer yes
zune setup                    # Zune type definitions for luau-lsp
zune run .zune/bundle.luau    # builds the api_types bundle
pesde install                 # package dependencies
```

Using the packages and running their Luau specs needs none of the following. Rebuilding any binary runs `.github/scripts/build-binaries.sh`, which needs Linux x86_64, Rust from `rust-toolchain.toml` (in `packages/symphonia/native`, the crate behind the `symphonia` binaries), cargo-zigbuild 0.24.0, CMake and make, and brings its own zig. Rust alone is enough to change and test the crate.

Every file `build-binaries.sh` builds (libopus, the macOS libsodium and libsymphonia) comes from the `build-binaries.yml` artifact, which you copy into the package. The others (libdave, the Linux and Windows libsodium) stay as they are until the pipeline covers them. CI rebuilds the files and compares them byte for byte with the committed ones. A local run on Linux x86_64 uses the same pinned zig, so it matches too.

## Checks

CI runs these in this order on every pull request. Run them before you commit. Seed the binary cache first and again after any change to a binary or a checksum: `opus` always loads its own checksummed libopus, never a system copy, and until a version's release tag exists its download fails with HTTP 404, so the tests read the committed files from the cache instead.

```sh
zune run .github/scripts/seedBinaryCache.luau # before the tests: copies the committed binaries into the cache
zune run .zune/fmt.luau                       # StyLua, config in stylua.toml
zune run .zune/lint.luau                      # Selene, config in selene.toml
zune run .zune/analyze.luau                   # luau-lsp type check, strict mode from .luaurc
zune run .zune/test.luau                      # every test
zune run .zune/test.luau packages/<name>      # one package's tests
```

When you change the crate, also run its Rust tests; CI's native workflow (`.github/workflows/native.yml`) runs them on Ubuntu:

```sh
cd packages/symphonia/native && cargo test --locked
```

`dave`, `opus`, `sodium` and `symphonia` call native libraries through FFI, which Zune provides; the first run downloads the library for your platform (`symphonia` loads its library on first use, not on require). On a runtime without FFI their native suites are reported as skipped; `DISCORD_LUAU_REQUIRE_FFI=1` (set in CI) turns that into an error. A spec that calls a native library requires `../src` directly (no `pcall`, so a load error fails the run), errors when `DISCORD_LUAU_REQUIRE_FFI` is set and FFI is missing, otherwise skips its suite, and never calls the library while the file loads. CI also runs these packages, and `audio`, whose specs decode files through `symphonia`, on Windows and macOS (`.github/workflows/native.yml`) when a pull request touches them. To replace a native binary, put the new file under `packages/<name>/binaries/<os>-<arch>/`, update its checksum in `sys.luau`, and point `binary.load`'s `version` at the package's next release; CI loads the binaries in your checkout, and the tag for that version is created when the release merges. `.github/scripts/build-binaries.sh` rebuilds libopus, the macOS libsodium and libsymphonia.

## Where code goes

- Discord object classes: `packages/classes/src/`
- Builders: `packages/builders/src/`
- REST endpoints: `packages/rest/src/<resource>.luau`
- Gateway shards and manager: `packages/websocket/src/`
- Cache and shared state: `packages/state/src/`
- Wire types and enums: `packages/api_types/src/`
- The `Bot` entry point: `packages/discord_luau/src/bot.luau`
- Runtime adapters: `packages/std_polyfills/src/<runtime>/<module>.luau`
- Test doubles (a local Discord gateway and REST server): `packages/discord_stub/src/`
- The Rust crate behind libsymphonia: `packages/symphonia/native/`; Rust changes and tests it; rebuilding any binary needs the toolchain described under Setup
- Each package exports from `packages/<name>/src/init.luau`.

Do not edit anything under `luau_packages/`; pesde generates it.

## Paradigms

Match the surrounding code. These are the conventions a formatter or linter will not catch.

- Classes are `local X = {}`, `X.Interface = {}`, `X.Prototype = {}`. Methods are `function X.Prototype.name(self: X, ...)` and are called with `:`. The constructor is `X.Interface.new(...)`. The module returns `X.Interface`. This keeps `self` typed in strict mode.
- Declare every field in `export type X = typeof(X.Prototype) & { ... }`, so strict mode catches a typo in `self.x`.
- Private helpers are plain methods, `function X.Prototype.name(self: X)`, called `self:name()`, with `@private` in their Moonwave block. No method or field takes a leading underscore. Do not write module-local functions that take `self`.
- Methods that wait on I/O end in `Async` and return `future.Future.new(function() ... end) :: future.FutureLike<string, T>`. Inside the future, fail with `assert` or `error`; the future turns that into an `Err`.
- Log through the package's logger at `debug`, `info`, `notice` or `warn`. `error`, `critical`, `alert` and `emergency` cancel the thread that logs them while the default sink is active, so a future that logs at those levels never resolves.
- Emitters are fields named `onX` (`onMessage`, `onShardReconnected`); listeners use `:listen` or `:listenOnce`; producers call `:invoke`. A listener callback may yield; an event that arrives while it is still running is handled in a new thread, so long work in one event never receives another event's arguments. Every `coroutine.resume` checks its result and logs the error at `warn` (never swallow it, never log at `error`).
- The cache stores the raw API object (`apiTypes.XObject`); classes are built from it on demand. `packages/rest` knows nothing about the cache.
- Requires use relative paths: dependencies as `require("../luau_packages/<name>")`, files in the same package as `./file`. Put dependency requires first, then a blank line, then same-package requires.
- Names are full words: `directoryPath`, not `dirPath`; `index`, not `i`. camelCase for locals, functions and files; PascalCase for classes and types; `SCREAMING_SNAKE_CASE` for constants; snake_case for package folders.
- Document classes, fields and methods with Moonwave `--[=[ ... ]=]` blocks; private methods take `@private`. Avoid other comments unless they explain a "why" the code cannot.
- Wire fields keep Discord's snake_case; class properties use camelCase.
- Use hyphens, never em-dashes, in code, comments, docs and changelogs.

## Tests

- Tests are frktest specs in `packages/<name>/tests/*.spec.luau`, split by concern across several files.
- Every bug fix needs a test that fails without the fix and passes with it. Run it both ways and report both.
- For gateway or REST behaviour, use `packages/discord_stub` (with `clock = "virtual"`) instead of writing a fake. If the stub lacks something, extend it with its own tests.
- Do not create `tests/support` or `tests/helpers` folders.

## Commits and pull requests

Full rules: `docs/ai/commits-and-pull-requests.md`. In short:

- Conventional Commits with the package folder as scope: `fix(websocket): reconnect after a failed resume`; several packages are comma-separated, `docs(rest,state): ...`. One change per commit.
- Add a line under `## [Unreleased]` in the `CHANGELOG.md` of every package you change. Never change package versions.
- An AI attribution trailer (`Co-Authored-By`) is welcome, unless the person you are working for tells you not to add one. Either way, say in the pull request description, in one line, that AI was used.
- Fill in `.github/PULL_REQUEST_TEMPLATE.md`; under "Other information", put how it was tested (commands and their output) and the AI note.

## Boundaries

- Never commit tokens or `.env.luau`. Ask the person you are working for to supply secrets at run time.
- Do not commit AI working files (plans, specs, notes, logs). Keep them out of the repository; `docs/` is the public documentation site.
- Ask a maintainer before you add, remove or upgrade a dependency, edit `.github/` or `.zune/` scripts, change a public API in a breaking way, or touch license text. Open an issue describing the change instead of making it.
- Do not publish packages or bump versions; maintainers release.
