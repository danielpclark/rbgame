//! The native half of rbgame.
//!
//! Everything in this crate is deliberately *thin*: it hands SDL (the pure
//! Rust translation in the `sdl3` crate) to Ruby as a small set of
//! primitive-argument methods under `Rbgame::Native`, and raises
//! `Rbgame::SDLError` when SDL reports a failure. The expressive, idiomatic
//! Ruby API (`Rbgame::Rect`, `Rbgame::Color`, `Rbgame::Canvas`,
//! `Rbgame::Game`, ...) lives in `lib/rbgame/` and is written in Ruby, where
//! Ruby's design tools (keyword arguments, blocks, `Data`, `Comparable`,
//! pattern matching) do a better job than any generated binding could.
//!
//! Rule of thumb for what belongs here: only what *must* touch SDL.

#[macro_use]
extern crate rutie;
extern crate lazy_static;

#[macro_use]
mod support;

mod audio;
mod camera;
mod clipboard;
mod events;
mod gamepad;
mod input;
mod renderer;
mod surface;
mod system;
mod window;

use rutie::{Module, Object};

/// Entry point called by the `rutie` gem (`Rutie.new(:rbgame_native).init`).
///
/// `Rbgame` and `Rbgame::Error`/`Rbgame::SDLError` are defined in Ruby before
/// the library is loaded; this function fills in `Rbgame::Native`.
#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn Init_rbgame_native() {
    let mut native = Module::from_existing("Rbgame").define_nested_module("Native");

    native.define(|module| {
        system::define(module);
        events::define(module);
        input::define(module);
        clipboard::define(module);
    });

    window::define(&mut native);
    renderer::define(&mut native);
    surface::define(&mut native);
    audio::define(&mut native);
    gamepad::define(&mut native);
    camera::define(&mut native);
}
