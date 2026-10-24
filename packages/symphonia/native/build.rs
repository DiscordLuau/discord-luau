//! Gives the macOS dylib the id `@rpath/libsymphonia.dylib`, not the build folder's path, at link time: `RUSTFLAGS`
//! would replace the per-target flags, and `install_name_tool` after linking would break the arm64 ad-hoc signature.

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    let target_vendor = std::env::var("CARGO_CFG_TARGET_VENDOR").unwrap_or_default();

    if target_vendor == "apple" {
        println!("cargo:rustc-cdylib-link-arg=-Wl,-install_name,@rpath/libsymphonia.dylib");
    }
}
