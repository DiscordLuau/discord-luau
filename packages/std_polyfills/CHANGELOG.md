# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `process.spawn(command, arguments)` starts a program without a shell and returns `read`, `wait`, `exited`, `kill`, `errorTail` and `errorEnded`, which turns true once stderr is read to its end (or its reader stopped after a kill or failed). At the end of stderr, `errorTail` holds its last line; after a kill, only what was read so far. `kill` never waits for the exit: it closes the program's stdout and stderr, so a program blocked on writing them exits even if it ignores SIGTERM, and stops it in the background. Only Zune has it; other runtimes raise `process.spawn is not supported on this runtime`
- `WebSocket.nextMessage()` returns a message and whether it arrived as a binary frame. Zune reports the frame type; the other runtimes return nil for it. `next()` is unchanged

### Fixed

- On Roblox, a WebStream signal no longer defers a waiting thread its owner already closed, and a socket `Error` after open is raised from `next()` instead of reading as a clean close
- On Lute, a socket `onerror` is raised from `next()`, and a failed `@lute/net/client` load keeps its cause in the message
- On Lune and Lute, `fileSystem.watch` reports an unreadable directory once on stderr, skips an entry whose metadata fails, and runs the callback in its own thread so a throwing callback no longer ends watching
- On Zune, `net.udpSocket` works on Windows. It no longer calls `connect`, which Zune runs through a TCP-only path there (ConnectEx) and which failed with "Unexpected", so voice UDP discovery could not open a socket and every voice join failed. The socket binds to `0.0.0.0` on an ephemeral port before its first receive, sends with `sendMsg` and skips datagrams from any address but its peer
- On Zune, `net.udpSocket` sends one datagram at a time. On macOS Zune keeps one pending write per socket, so a send that overlapped another, such as a voice keepalive during an audio frame, was never sent and never returned. A send that starts while another is in flight now waits its turn, in order
- On Zune, a socket no longer resumes a waiting thread that its owner closed after a message queued the wake but before the wake ran. Zune resumes a closed thread it deferred and printed "cannot resume dead coroutine"
- On Zune, native memory freed through `ffi.free` goes back to a pool that `ffi.alloc` and `ffi.dupe` reuse (zeroed) instead of returning to the system allocator. Zune leaves a freed pointer object cached by address until it is garbage collected, so a native library that received that address from `malloc` (a new libopus decoder or libdave session) got the dead object and failed with "unavailable address" at random. Freeing a pooled block twice raises "Double free"
- On Zune, closing a WebSocket whose waiting thread was already closed (as a voice connection does when it tears down) no longer raises "cannot resume non-suspended coroutine"
- On Zune, a block reused from the FFI pool no longer keeps a tag set on it before it was freed
- On Zune, stopping a spawned program no longer crashes Zune on macOS, or on Linux without io_uring (such as a container that blocks it). There Zune reads a pipe on a worker thread that closing the pipe cannot stop, and the worker's late result freed the read a second time, so `kill` now closes a pipe only once no read waits on it. It also sends SIGTERM through libc on Linux and macOS, since the second wait Zune's own `kill` adds on macOS took the exit event and `wait` never returned
- On Zune, stopping a spawned program on Windows no longer leaves Zune's own `kill` waiting forever. Its second wait never completed while the exit watcher waited, and now and then it corrupted the event loop, so a run printed its results and then spun without exiting. `kill` now calls TerminateProcess through kernel32 on the program's handle

### Changed

- The `ffi.getNull` docs say the shared null must never be tagged

## 0.0.4

### Fixed

- Lute `task.delay` returns a thread, so `task.cancel` works on it
- Lute `io.stderrWrite` no longer prints a stray `2`; it writes to stdout because Lute has no stderr writer
- Lune `process.getArch` returns the CPU architecture
- Lune `fileSystem.stat` returns the size of a file
- Zune `serde.decode("json", buffer)` accepts a buffer
- Eryx `ffi` requires `@eryx/experimental/_ffi`

### Changed

- `runtime.capabilities().ffi` is `true` on Zune again, so `dave`, `opus` and `sodium` work there; tested on Linux x64 and Windows x64 with Zune 0.5.9
- Verified on Lune 0.11.0, Zune 0.5.9, Lute 1.0.1-nightly.20261021 and Eryx 0.1.0

## 0.0.3

### Added

- Lute runtime support: full polyfill implementation across all modules (`task`, `process`, `net`, `fileSystem`, `datetime`, `stdio`, `io`, `serde`)
- Lute runtime detection via `pcall(require, "@lute/fs")` probe - Lute does not override `_VERSION` so it cannot be identified by version string alone
- All dispatch layers now route to Lute implementations instead of erroring with an unsupported-runtime message
- `process.onSignal` dispatch extended to support Lute alongside Zune
- Lute `serde.decode` sanitizes JSON null - Lute's JSON parser returns a userdata singleton for null values and encodes null-type flag fields (e.g. `"premium_subscriber": null`) as `{[null_userdata] = true}` entries; both forms are now recursively converted to Lua `nil`
- Lute `net.request` builds query parameters directly into the URL, as Lute's native HTTP client ignores the `query` field in the opts table
- Lute `fileSystem.stat` returns `{kind = "none"}` for missing paths instead of throwing

### Fixed

- Lute `onSignal` capability corrected to `true` - signal handling is available via `@std/process`
- Zune `ffi` capability corrected to `false`
- `task.defer`, `task.delay`, and `task.spawn` variadic argument type widened from `T...` to `any` to resolve type errors at call sites

## 0.0.2

### Fixed

- Zune HTTP response body buffer normalised to a string before returning, preventing downstream type errors
- Zune net request options extended with `max_body_size` through a cast to avoid a strict-mode table error
- Zune `fs.watch` callback parameter type now inferred from the Zune typedef instead of a conflicting annotation
- `ffi.fn` Eryx branch now returns the result correctly under strict type analysis
- Resolve `@eryx/` requires for type analysis by adding Eryx typedef stubs and a `.luaurc` alias
- Declare missing Roblox globals (`task`, `Enum`, `DateTime`, `HttpService`) for type analysis
- HTTP response body size limit increased to accommodate larger API responses

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
