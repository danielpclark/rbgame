//! Keyboard and mouse state, key naming. `Rbgame::Native.*`.

use rutie::rubymodule;

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use sdl3::events::keyboard::{self, Keycode, Keymod, Scancode};
    use sdl3::events::mouse;

    use crate::support::{Int, Truthy};

    #[ruby(name = "key_pressed?")]
    pub fn key_pressed(scancode: Int) -> bool {
        keyboard::is_pressed(Scancode(scancode.0 as u16))
    }

    pub fn pressed_scancodes() -> Vec<i64> {
        let state = keyboard::keyboard_state();
        state.iter().enumerate().filter(|(_, down)| **down).map(|(i, _)| i as i64).collect()
    }

    pub fn mod_state() -> i64 {
        keyboard::mod_state().0 as i64
    }

    pub fn mouse_position() -> (f64, f64) {
        let (x, y, _) = mouse::mouse_state();
        (x as f64, y as f64)
    }

    pub fn mouse_buttons() -> i64 {
        let (_, _, buttons) = mouse::mouse_state();
        buttons.0 as i64
    }

    pub fn key_name(keycode: Int) -> String {
        Keycode(keycode.0 as u32).name()
    }

    pub fn key_from_name(name: &str) -> i64 {
        Keycode::from_name(name).0 as i64
    }

    pub fn scancode_name(scancode: Int) -> String {
        Scancode(scancode.0 as u16).name().to_string()
    }

    pub fn scancode_from_name(name: &str) -> i64 {
        Scancode::from_name(name).map(|s| s.0).unwrap_or(0) as i64
    }

    pub fn key_from_scancode(scancode: Int) -> i64 {
        keyboard::key_from_scancode(Scancode(scancode.0 as u16), Keymod::NONE, false).0 as i64
    }

    pub fn scancode_from_key(keycode: Int) -> i64 {
        let (scancode, _) = keyboard::scancode_from_key(Keycode(keycode.0 as u32));
        scancode.0 as i64
    }

    #[ruby(name = "cursor_visible=")]
    pub fn set_cursor_visible(visible: Truthy) {
        if visible.0 {
            mouse::show_cursor();
        } else {
            mouse::hide_cursor();
        }
    }

    #[ruby(name = "cursor_visible?")]
    pub fn cursor_visible() -> bool {
        mouse::cursor_visible()
    }
}

pub fn define() {
    functions::define_ruby();
}
