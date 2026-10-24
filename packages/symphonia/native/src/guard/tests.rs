//! Turning a caught panic's payload into its error.

use super::*;

#[test]
fn panic_payloads_become_the_message() {
    let from_str = panic_error(&"broken").to_string();
    let from_string = panic_error(&String::from("also broken")).to_string();
    let from_other = panic_error(&42_u8).to_string();

    assert_eq!(from_str, "symphonia wrapper panicked: broken");
    assert_eq!(from_string, "symphonia wrapper panicked: also broken");
    assert_eq!(from_other, "symphonia wrapper panicked: a panic without a message");
}
