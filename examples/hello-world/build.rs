// Test build script works.
fn main() {
    println!("cargo:rustc-cfg=foo=\"bar\"");
}
