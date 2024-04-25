pub mod nacl;
pub mod util;

use nacl::{KEY_SIZE, NONCE_SIZE, Encrypted};
use util::base64_decode;
use arrayvec::ArrayVec;

fn main() {
    let args = std::env::args().collect::<Vec<String>>();

    let key = ArrayVec::<u8, KEY_SIZE>::from_iter(args.get(1).map(base64_decode).expect("No key provided"));
    let nonce = ArrayVec::<u8, NONCE_SIZE>::from_iter(args.get(2).map(base64_decode).expect("No nonce provided"));
    let payload = args.get(3).map(base64_decode).expect("No payload provided");

    println!("{}", Encrypted {
        key, nonce, payload
    })
}

