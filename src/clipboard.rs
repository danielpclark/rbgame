//! The system clipboard's text, through SDL. Without a platform clipboard
//! (the offscreen driver, say) SDL keeps the text itself.

use rutie::rubymodule;

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use sdl3::video::clipboard;

    use crate::support::NativeResult;
    use crate::surface::Surface;

    pub fn clipboard_text() -> NativeResult<String> {
        Ok(clipboard::clipboard_text()?)
    }

    pub fn set_clipboard_text(text: &str) -> NativeResult<()> {
        Ok(clipboard::set_clipboard_text(text)?)
    }

    #[ruby(name = "clipboard_has_text?")]
    pub fn clipboard_has_text() -> bool {
        clipboard::has_clipboard_text().unwrap_or(false)
    }

    pub fn clear_clipboard() -> NativeResult<()> {
        Ok(clipboard::clear_clipboard_data()?)
    }

    // An image on the clipboard as a Surface, or nil.
    pub fn clipboard_image() -> Option<Surface> {
        sdl3_image::clipboard_image().ok().map(Surface::from)
    }
}

pub fn define() {
    functions::define_ruby();
}
