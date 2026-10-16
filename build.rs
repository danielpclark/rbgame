// Rutie's `no-link` feature leaves libruby to the `ruby` process that loads
// the extension. Linux and Windows linkers allow a shared library's symbols
// to stay undefined until then; Apple's doesn't, so the `rb_*` symbols are
// left for the loader explicitly. Only this crate can say so: a link argument
// from a dependency's build script never reaches the cdylib.
fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos") {
        println!("cargo:rustc-cdylib-link-arg=-Wl,-undefined,dynamic_lookup");
    }
}
