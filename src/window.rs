//! `Rbgame::Native::Window`: an SDL window handle.

use rutie::{rubyclass, rubymethods, rubymodule};
use sdl3::video::Window as SdlWindow;

use crate::support::{state_error, Int, NativeResult, Truthy};
use crate::surface::Surface;

/// Instances come only from Rust (`Native.create_window`), never from
/// `Window.new`; the window is destroyed with the object or by `destroy`.
#[rubyclass(path = "Rbgame::Native::Window", allocator = false)]
pub struct Window {
    window: Option<SdlWindow>,
}

impl Window {
    pub fn get(&self) -> NativeResult<&SdlWindow> {
        match &self.window {
            Some(window) => Ok(window),
            None => state_error("the window has been destroyed"),
        }
    }
}

impl Drop for Window {
    fn drop(&mut self) {
        if let Some(window) = self.window.take() {
            window.destroy();
        }
    }
}

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use sdl3::events::window::WindowFlags;
    use sdl3::video::Window as SdlWindow;

    use super::Window;
    use crate::support::{Int, NativeResult};

    pub fn create_window(title: &str, width: Int, height: Int, flags: Int) -> NativeResult<Window> {
        let window = SdlWindow::create(title, width.0 as i32, height.0 as i32, WindowFlags(flags.0 as u64))?;
        Ok(Window { window: Some(window) })
    }
}

#[rubymethods]
impl Window {
    pub fn id(&self) -> NativeResult<i64> {
        Ok(self.get()?.id() as i64)
    }

    pub fn title(&self) -> NativeResult<String> {
        Ok(self.get()?.title()?)
    }

    #[ruby(name = "title=")]
    pub fn set_title(&self, title: &str) -> NativeResult<()> {
        Ok(self.get()?.set_title(title)?)
    }

    pub fn size(&self) -> NativeResult<(i64, i64)> {
        let (w, h) = self.get()?.size()?;
        Ok((w as i64, h as i64))
    }

    pub fn resize(&self, width: Int, height: Int) -> NativeResult<()> {
        Ok(self.get()?.set_size(width.0 as i32, height.0 as i32)?)
    }

    pub fn size_in_pixels(&self) -> NativeResult<(i64, i64)> {
        let (w, h) = self.get()?.size_in_pixels()?;
        Ok((w as i64, h as i64))
    }

    pub fn position(&self) -> NativeResult<(i64, i64)> {
        let (x, y) = self.get()?.position()?;
        Ok((x as i64, y as i64))
    }

    pub fn move_to(&self, x: Int, y: Int) -> NativeResult<()> {
        Ok(self.get()?.set_position(x.0 as i32, y.0 as i32)?)
    }

    pub fn show(&self) -> NativeResult<()> {
        Ok(self.get()?.show()?)
    }

    pub fn hide(&self) -> NativeResult<()> {
        Ok(self.get()?.hide()?)
    }

    pub fn raise_window(&self) -> NativeResult<()> {
        Ok(self.get()?.raise()?)
    }

    #[ruby(name = "fullscreen=")]
    pub fn set_fullscreen(&self, fullscreen: Truthy) -> NativeResult<()> {
        Ok(self.get()?.set_fullscreen(fullscreen.0)?)
    }

    #[ruby(name = "resizable=")]
    pub fn set_resizable(&self, resizable: Truthy) -> NativeResult<()> {
        Ok(self.get()?.set_resizable(resizable.0)?)
    }

    #[ruby(name = "bordered=")]
    pub fn set_bordered(&self, bordered: Truthy) -> NativeResult<()> {
        Ok(self.get()?.set_bordered(bordered.0)?)
    }

    pub fn set_minimum_size(&self, width: Int, height: Int) -> NativeResult<()> {
        Ok(self.get()?.set_minimum_size(width.0 as i32, height.0 as i32)?)
    }

    pub fn flags(&self) -> NativeResult<i64> {
        Ok(self.get()?.flags()?.0 as i64)
    }

    #[ruby(name = "icon=")]
    pub fn set_icon(&self, icon: &Surface) -> NativeResult<()> {
        Ok(self.get()?.set_icon(icon.get())?)
    }

    pub fn start_text_input(&self) -> NativeResult<()> {
        Ok(self.get()?.start_text_input()?)
    }

    pub fn stop_text_input(&self) -> NativeResult<()> {
        Ok(self.get()?.stop_text_input()?)
    }

    #[ruby(name = "text_input_active?")]
    pub fn text_input_active(&self) -> NativeResult<bool> {
        Ok(self.get()?.text_input_active()?)
    }

    pub fn destroy(&mut self) {
        if let Some(window) = self.window.take() {
            window.destroy();
        }
    }

    #[ruby(name = "destroyed?")]
    pub fn destroyed(&self) -> bool {
        self.window.is_none()
    }
}

pub fn define() {
    functions::define_ruby();
    Window::define_ruby();
}
