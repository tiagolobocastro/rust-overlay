// Test proc-macro works.
// https://github.com/oxalica/rust-overlay/issues/54
#[derive(Debug, thiserror::Error)]
pub enum Err {
    #[error("My error")]
    MyError,
}

// Test build script works.
#[cfg(foo = "bar")]
fn main() {
    // Trigger a clippy warning.
    loop {
        break;
    }
    println!("Hello, world!");
}
