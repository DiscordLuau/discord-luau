use std::fmt::Display;

use crate::util::base64_encode;
use arrayvec::ArrayVec;
use crypto_secretbox::{
    aead::{Aead, Payload},
    KeyInit, Nonce, XSalsa20Poly1305,
};

pub const KEY_SIZE: usize = 32;
pub const NONCE_SIZE: usize = 24;

#[derive(Debug, Clone)]
pub struct Encrypted {
    pub payload: Vec<u8>,
    pub nonce: ArrayVec<u8, NONCE_SIZE>,
    pub key: ArrayVec<u8, KEY_SIZE>,
}

impl Encrypted {
    fn decrypt(self) -> Vec<u8> {
        XSalsa20Poly1305::new(
            &self
                .key
                .into_inner()
                .expect("Key was of incorrect size")
                .into(),
        )
        .decrypt(
            &Nonce::from_iter(self.nonce),
            Payload::from(self.payload.as_ref()),
        )
        .expect("Failed to decrypt")
    }
}

impl Display for Encrypted {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        let cloned_self = self.clone();
        write!(f, "{}", base64_encode(cloned_self.decrypt()))
    }
}
