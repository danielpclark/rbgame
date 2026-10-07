//! The system clipboard's text, through SDL. Without a platform clipboard
//! (the offscreen driver, say) SDL keeps the text itself.

use rutie::{AnyObject, Boolean, Module, NilClass, Object, RString};
use sdl3::video::clipboard;

use crate::support::{str_of, OrRaise};

methods!(
    AnyObject,
    _rtself,

    fn clip_text() -> RString {
        RString::new_utf8(&clipboard::clipboard_text().or_raise())
    }

    fn clip_set_text(text: RString) -> NilClass {
        clipboard::set_clipboard_text(&str_of(text)).or_raise();
        NilClass::new()
    }

    fn clip_has_text() -> Boolean {
        Boolean::new(clipboard::has_clipboard_text().unwrap_or(false))
    }

    fn clip_clear() -> NilClass {
        clipboard::clear_clipboard_data().or_raise();
        NilClass::new()
    }

    // An image on the clipboard as a Surface, or nil.
    fn clip_image() -> AnyObject {
        match sdl3_image::clipboard_image() {
            Ok(surface) => crate::surface::wrap(surface),
            Err(_) => NilClass::new().to_any_object(),
        }
    }
);

pub fn define(module: &mut Module) {
    module.def_self("clipboard_text", clip_text);
    module.def_self("set_clipboard_text", clip_set_text);
    module.def_self("clipboard_has_text?", clip_has_text);
    module.def_self("clear_clipboard", clip_clear);
    module.def_self("clipboard_image", clip_image);
}
