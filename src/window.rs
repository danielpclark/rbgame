//! `Rbgame::Native::Window`: an SDL window handle.

use rutie::{AnyObject, Array, Boolean, Fixnum, Module, NilClass, Object, RString};
use sdl3::events::window::WindowFlags;
use sdl3::video::Window;

use crate::support::{i32_of, i64_of, native, pair, raise_state, str_of, truthy, OrRaise};
use crate::surface::RbSurface;

pub struct WindowBox {
    window: Option<Window>,
}

impl WindowBox {
    fn get(&self) -> &Window {
        self.window
            .as_ref()
            .unwrap_or_else(|| raise_state("the window has been destroyed"))
    }
}

impl Drop for WindowBox {
    fn drop(&mut self) {
        if let Some(window) = self.window.take() {
            window.destroy();
        }
    }
}

wrappable_struct!(WindowBox, WindowWrapper, WINDOW_WRAPPER);
native_class!(RbWindow, "Window");

pub fn wrap(window: Window) -> AnyObject {
    native()
        .get_nested_class("Window")
        .wrap_data(WindowBox { window: Some(window) }, &*WINDOW_WRAPPER)
}

impl RbWindow {
    pub fn window(&self) -> &Window {
        self.get_data(&*WINDOW_WRAPPER).get()
    }
}

methods!(
    AnyObject,
    _rtself,

    fn win_create(title: RString, width: AnyObject, height: AnyObject, flags: AnyObject) -> AnyObject {
        let window = Window::create(
            &str_of(title),
            i32_of(width, "width"),
            i32_of(height, "height"),
            WindowFlags(i64_of(flags, "flags") as u64),
        )
        .or_raise();
        wrap(window)
    }
);

methods!(
    RbWindow,
    rtself,

    fn win_id() -> Fixnum {
        Fixnum::new(rtself.window().id() as i64)
    }

    fn win_title() -> RString {
        RString::new_utf8(&rtself.window().title().or_raise())
    }

    fn win_set_title(title: RString) -> NilClass {
        rtself.window().set_title(&str_of(title)).or_raise();
        NilClass::new()
    }

    fn win_size() -> Array {
        let (w, h) = rtself.window().size().or_raise();
        pair(w as i64, h as i64)
    }

    fn win_set_size(width: AnyObject, height: AnyObject) -> NilClass {
        rtself.window().set_size(i32_of(width, "width"), i32_of(height, "height")).or_raise();
        NilClass::new()
    }

    fn win_size_in_pixels() -> Array {
        let (w, h) = rtself.window().size_in_pixels().or_raise();
        pair(w as i64, h as i64)
    }

    fn win_position() -> Array {
        let (x, y) = rtself.window().position().or_raise();
        pair(x as i64, y as i64)
    }

    fn win_set_position(x: AnyObject, y: AnyObject) -> NilClass {
        rtself.window().set_position(i32_of(x, "x"), i32_of(y, "y")).or_raise();
        NilClass::new()
    }

    fn win_show() -> NilClass {
        rtself.window().show().or_raise();
        NilClass::new()
    }

    fn win_hide() -> NilClass {
        rtself.window().hide().or_raise();
        NilClass::new()
    }

    fn win_raise() -> NilClass {
        rtself.window().raise().or_raise();
        NilClass::new()
    }

    fn win_set_fullscreen(fullscreen: AnyObject) -> NilClass {
        rtself.window().set_fullscreen(truthy(fullscreen)).or_raise();
        NilClass::new()
    }

    fn win_set_resizable(resizable: AnyObject) -> NilClass {
        rtself.window().set_resizable(truthy(resizable)).or_raise();
        NilClass::new()
    }

    fn win_set_bordered(bordered: AnyObject) -> NilClass {
        rtself.window().set_bordered(truthy(bordered)).or_raise();
        NilClass::new()
    }

    fn win_set_minimum_size(width: AnyObject, height: AnyObject) -> NilClass {
        rtself
            .window()
            .set_minimum_size(i32_of(width, "width"), i32_of(height, "height"))
            .or_raise();
        NilClass::new()
    }

    fn win_flags() -> Fixnum {
        Fixnum::new(rtself.window().flags().or_raise().0 as i64)
    }

    fn win_set_icon(icon: RbSurface) -> NilClass {
        let icon = crate::support::arg(icon);
        rtself.window().set_icon(icon.surface()).or_raise();
        NilClass::new()
    }

    fn win_start_text_input() -> NilClass {
        rtself.window().start_text_input().or_raise();
        NilClass::new()
    }

    fn win_stop_text_input() -> NilClass {
        rtself.window().stop_text_input().or_raise();
        NilClass::new()
    }

    fn win_text_input_active() -> Boolean {
        Boolean::new(rtself.window().text_input_active().or_raise())
    }

    fn win_destroy() -> NilClass {
        if let Some(window) = rtself.get_data_mut(&*WINDOW_WRAPPER).window.take() {
            window.destroy();
        }
        NilClass::new()
    }

    fn win_destroyed() -> Boolean {
        Boolean::new(rtself.get_data(&*WINDOW_WRAPPER).window.is_none())
    }
);

pub fn define(native: &mut Module) {
    native.def_self("create_window", win_create);

    let mut klass = native.define_nested_class("Window", None);
    // Instances come only from Rust (`wrap_data`), never from `Window.new`.
    klass.undef_alloc_func();
    klass.define(|klass| {
        klass.def("id", win_id);
        klass.def("title", win_title);
        klass.def("title=", win_set_title);
        klass.def("size", win_size);
        klass.def("resize", win_set_size);
        klass.def("size_in_pixels", win_size_in_pixels);
        klass.def("position", win_position);
        klass.def("move_to", win_set_position);
        klass.def("show", win_show);
        klass.def("hide", win_hide);
        klass.def("raise_window", win_raise);
        klass.def("fullscreen=", win_set_fullscreen);
        klass.def("resizable=", win_set_resizable);
        klass.def("bordered=", win_set_bordered);
        klass.def("set_minimum_size", win_set_minimum_size);
        klass.def("flags", win_flags);
        klass.def("icon=", win_set_icon);
        klass.def("start_text_input", win_start_text_input);
        klass.def("stop_text_input", win_stop_text_input);
        klass.def("text_input_active?", win_text_input_active);
        klass.def("destroy", win_destroy);
        klass.def("destroyed?", win_destroyed);
    });
}
