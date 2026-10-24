//! The crate's tests, as one binary over its Rust API, its C ABI and the hooks of its `testing` feature.

#![expect(clippy::unwrap_used, clippy::expect_used, clippy::panic, reason = "test helpers")]

mod files;
mod util;

mod abi;
mod allocations;
mod errors;
mod mix;
mod passthrough;
mod resample;
mod session;
mod stream;
mod stream_chunks;
