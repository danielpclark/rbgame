//! Keyboard and mouse state, key naming. `Rbgame::Native.*`.

use rutie::{AnyObject, Array, Boolean, Fixnum, Module, NilClass, Object, RString};
use sdl3::events::keyboard::{self, Keycode, Keymod, Scancode};
use sdl3::events::mouse;

use crate::support::{fpair, i64_of, ints_array, str_of, truthy};

methods!(
    AnyObject,
    _rtself,

    fn in_key_pressed(scancode: AnyObject) -> Boolean {
        Boolean::new(keyboard::is_pressed(Scancode(i64_of(scancode, "scancode") as u16)))
    }

    fn in_pressed_scancodes() -> Array {
        let state = keyboard::keyboard_state();
        ints_array(state.iter().enumerate().filter(|(_, down)| **down).map(|(i, _)| i as i64))
    }

    fn in_mod_state() -> Fixnum {
        Fixnum::new(keyboard::mod_state().0 as i64)
    }

    fn in_mouse_position() -> Array {
        let (x, y, _) = mouse::mouse_state();
        fpair(x as f64, y as f64)
    }

    fn in_mouse_buttons() -> Fixnum {
        let (_, _, buttons) = mouse::mouse_state();
        Fixnum::new(buttons.0 as i64)
    }

    fn in_key_name(keycode: AnyObject) -> RString {
        RString::new_utf8(&Keycode(i64_of(keycode, "keycode") as u32).name())
    }

    fn in_key_from_name(name: RString) -> Fixnum {
        Fixnum::new(Keycode::from_name(&str_of(name)).0 as i64)
    }

    fn in_scancode_name(scancode: AnyObject) -> RString {
        RString::new_utf8(&Scancode(i64_of(scancode, "scancode") as u16).name())
    }

    fn in_scancode_from_name(name: RString) -> Fixnum {
        let code = Scancode::from_name(&str_of(name)).map(|s| s.0).unwrap_or(0);
        Fixnum::new(code as i64)
    }

    fn in_key_from_scancode(scancode: AnyObject) -> Fixnum {
        let scancode = Scancode(i64_of(scancode, "scancode") as u16);
        Fixnum::new(keyboard::key_from_scancode(scancode, Keymod::NONE, false).0 as i64)
    }

    fn in_scancode_from_key(keycode: AnyObject) -> Fixnum {
        let (scancode, _) = keyboard::scancode_from_key(Keycode(i64_of(keycode, "keycode") as u32));
        Fixnum::new(scancode.0 as i64)
    }

    fn in_set_cursor_visible(visible: AnyObject) -> NilClass {
        if truthy(visible) {
            mouse::show_cursor();
        } else {
            mouse::hide_cursor();
        }
        NilClass::new()
    }

    fn in_cursor_visible() -> Boolean {
        Boolean::new(mouse::cursor_visible())
    }
);

pub fn define(module: &mut Module) {
    module.def_self("key_pressed?", in_key_pressed);
    module.def_self("pressed_scancodes", in_pressed_scancodes);
    module.def_self("mod_state", in_mod_state);
    module.def_self("mouse_position", in_mouse_position);
    module.def_self("mouse_buttons", in_mouse_buttons);
    module.def_self("key_name", in_key_name);
    module.def_self("key_from_name", in_key_from_name);
    module.def_self("scancode_name", in_scancode_name);
    module.def_self("scancode_from_name", in_scancode_from_name);
    module.def_self("key_from_scancode", in_key_from_scancode);
    module.def_self("scancode_from_key", in_scancode_from_key);
    module.def_self("cursor_visible=", in_set_cursor_visible);
    module.def_self("cursor_visible?", in_cursor_visible);
}
