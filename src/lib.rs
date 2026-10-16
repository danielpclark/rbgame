//! The native half of rbgame.
//!
//! Everything in this crate is deliberately *thin*: it hands SDL (the pure
//! Rust translation in the `sdl3` crate) to Ruby as a small set of
//! primitive-argument methods under `Rbgame::Native`, and returns
//! `Rbgame::SDLError` when SDL reports a failure. The expressive, idiomatic
//! Ruby API (`Rbgame::Rect`, `Rbgame::Color`, `Rbgame::Canvas`,
//! `Rbgame::Game`, ...) lives in `lib/rbgame/` and is written in Ruby, where
//! Ruby's design tools (keyword arguments, blocks, `Data`, `Comparable`,
//! pattern matching) do a better job than any generated binding could.
//!
//! The classes are ordinary Rust structs under Rutie's `#[rubyclass]`, their
//! methods `#[rubymethods]` blocks, and the module's functions
//! `#[rubymodule]` blocks: arguments and results convert on the way through,
//! and an `Err` is raised once the method's values are dropped.
//!
//! Rule of thumb for what belongs here: only what *must* touch SDL.

mod support;

mod camera;
mod clipboard;
mod events;
mod font;
mod gamepad;
mod input;
mod mixer;
mod music;
mod renderer;
mod sensor;
mod surface;
mod system;
mod window;

/// Entry point called by the `rutie` gem (`Rutie.new(:rbgame_native).init`).
///
/// `Rbgame` and `Rbgame::Error`/`Rbgame::SDLError` are defined in Ruby before
/// the library is loaded; this function fills in `Rbgame::Native`.
#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn Init_rbgame_native() {
    system::define();
    events::define();
    input::define();
    clipboard::define();
    window::define();
    renderer::define();
    surface::define();
    gamepad::define();
    camera::define();
    sensor::define();
    music::define();
    mixer::define();
    font::define();
}
