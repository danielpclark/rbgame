//! `Rbgame::Native::Font`: a font file through SDL_ttf (every format
//! FreeType reads). Text crosses as UTF-8 and comes back as
//! `Rbgame::Native::Surface`s.

use std::sync::Once;

use rutie::{rubyclass, rubymethods};
use sdl3::video::Color;
use sdl3_ttf::Font as SdlFont;

use crate::support::{state_error, Chan, Int, NativeResult, Num, OptInt};
use crate::surface::Surface;

static TTF_INIT: Once = Once::new();

fn ensure_init() {
    TTF_INIT.call_once(|| {
        let _ = sdl3_ttf::init();
    });
}

/// Instances come only from `Font.open`.
#[rubyclass(path = "Rbgame::Native::Font", allocator = false)]
pub struct Font {
    font: Option<SdlFont>,
}

impl Font {
    fn get(&self) -> NativeResult<&SdlFont> {
        match &self.font {
            Some(font) => Ok(font),
            None => state_error("font is closed"),
        }
    }
}

#[rubymethods]
impl Font {
    pub fn open(path: &str, points: Num) -> NativeResult<Font> {
        ensure_init();
        Ok(Font { font: Some(SdlFont::open(path, points.0 as f32)?) })
    }

    pub fn size(&self) -> NativeResult<f64> {
        Ok(self.get()?.size() as f64)
    }

    #[ruby(name = "size=")]
    pub fn set_size(&self, points: Num) -> NativeResult<()> {
        Ok(self.get()?.set_size(points.0 as f32)?)
    }

    pub fn height(&self) -> NativeResult<i64> {
        Ok(self.get()?.height() as i64)
    }

    pub fn ascent(&self) -> NativeResult<i64> {
        Ok(self.get()?.ascent() as i64)
    }

    pub fn line_skip(&self) -> NativeResult<i64> {
        Ok(self.get()?.line_skip() as i64)
    }

    pub fn family_name(&self) -> NativeResult<Option<String>> {
        Ok(self.get()?.family_name())
    }

    #[ruby(name = "fixed_width?")]
    pub fn fixed_width(&self) -> NativeResult<bool> {
        Ok(self.get()?.is_fixed_width())
    }

    // SDL_ttf's style bits: 1 bold, 2 italic, 4 underline, 8 strikethrough.
    pub fn style(&self) -> NativeResult<i64> {
        Ok(self.get()?.style() as i64)
    }

    #[ruby(name = "style=")]
    pub fn set_style(&self, bits: Int) -> NativeResult<()> {
        self.get()?.set_style(bits.0 as u32);
        Ok(())
    }

    pub fn outline(&self) -> NativeResult<i64> {
        Ok(self.get()?.outline() as i64)
    }

    #[ruby(name = "outline=")]
    pub fn set_outline(&self, pixels: Int) -> NativeResult<()> {
        Ok(self.get()?.set_outline(pixels.0 as i32)?)
    }

    // [width, height] of `text`, wrapped at `wrap` pixels when not nil.
    pub fn measure(&self, text: &str, wrap: OptInt) -> NativeResult<(i64, i64)> {
        let font = self.get()?;
        let (w, h) = match wrap.0 {
            Some(wrap) => font.string_size_wrapped(text, wrap as i32)?,
            None => font.string_size(text)?,
        };
        Ok((w as i64, h as i64))
    }

    // Anti-aliased RGBA; `wrap` as in `measure`.
    pub fn render(&self, text: &str, r: Chan, g: Chan, b: Chan, a: Chan, wrap: OptInt) -> NativeResult<Surface> {
        let font = self.get()?;
        let color = Color { r: r.0, g: g.0, b: b.0, a: a.0 };
        let surface = match wrap.0 {
            Some(wrap) => font.render_text_blended_wrapped(text, color, wrap as i32)?,
            None => font.render_text_blended(text, color)?,
        };
        Ok(Surface::from(surface))
    }

    pub fn close(&mut self) {
        self.font = None;
    }
}

pub fn define() {
    Font::define_ruby();
}
