fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    let target_vendor = std::env::var("CARGO_CFG_TARGET_VENDOR").unwrap_or_default();

    if target_vendor == "apple" {
        println!("cargo:rustc-cdylib-link-arg=-Wl,-install_name,@rpath/libsymphonia.dylib");
    }
}
