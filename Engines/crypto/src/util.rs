use base64::Engine;

pub fn base64_decode(encoded: &String) -> Vec<u8> {
    base64::engine::general_purpose::STANDARD.decode(encoded).expect("Failed to decode base64")
}

pub fn base64_encode(encoded: Vec<u8>) -> String {
    base64::engine::general_purpose::STANDARD.encode(encoded)
}