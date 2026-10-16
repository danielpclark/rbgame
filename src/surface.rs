//! `Rbgame::Native::Surface`: a CPU-side image.

use rutie::derive::{Bytes, RubyClass};
use rutie::{rubyclass, rubymethods, rubymodule, AnyObject};
use sdl3::video::{BlendMode, Color, FlipMode, Rect, ScaleMode, Surface as SdlSurface};

use crate::support::{arg_error, rect_of, Chan, Int, NativeError, NativeResult, Num, OptInt};

/// Instances come only from Rust, never from `Surface.new`.
#[rubyclass(path = "Rbgame::Native::Surface", allocator = false)]
pub struct Surface {
    surface: SdlSurface<'static>,
}

impl From<SdlSurface<'static>> for Surface {
    fn from(surface: SdlSurface<'static>) -> Self {
        Surface { surface }
    }
}

impl Surface {
    pub fn get(&self) -> &SdlSurface<'static> {
        &self.surface
    }

    pub fn get_mut(&mut self) -> &mut SdlSurface<'static> {
        &mut self.surface
    }
}

pub fn blend_mode_of(value: Int) -> BlendMode {
    BlendMode(value.0 as u32)
}

pub fn scale_mode_of(value: Int) -> NativeResult<ScaleMode> {
    match value.0 {
        0 => Ok(ScaleMode::Nearest),
        1 => Ok(ScaleMode::Linear),
        2 => Ok(ScaleMode::PixelArt),
        other => arg_error(&format!("unknown scale mode {other}")),
    }
}

pub fn flip_mode_of(value: Int) -> NativeResult<FlipMode> {
    match value.0 {
        0 => Ok(FlipMode::None),
        1 => Ok(FlipMode::Horizontal),
        2 => Ok(FlipMode::Vertical),
        other => arg_error(&format!("unknown flip mode {other}")),
    }
}

fn color_of(r: Chan, g: Chan, b: Chan, a: Chan) -> Color {
    Color::new(r.0, g.0, b.0, a.0)
}

fn channels(color: Color) -> (i64, i64, i64, i64) {
    (color.r as i64, color.g as i64, color.b as i64, color.a as i64)
}

/// Another surface passed to a method on this one, borrowed mutably: the
/// same surface (already borrowed by the method) is an argument error.
fn other_surface(object: &AnyObject) -> NativeResult<rutie::derive::BorrowedMut<Surface>> {
    Surface::borrow_mut_from(object).map_err(|exception| {
        if Surface::is_instance(object) {
            NativeError::Arg("a surface cannot be blitted onto itself".to_owned())
        } else {
            NativeError::Ruby(exception)
        }
    })
}

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use rutie::AnyObject;
    use sdl3::video::{PixelFormat, Surface as SdlSurface};

    use super::Surface;
    use crate::support::{arg_error, i32s, Int, NativeResult};
    use rutie::derive::RubyClass;

    pub fn create_surface(width: Int, height: Int) -> NativeResult<Surface> {
        Ok(Surface::from(SdlSurface::new(width.0 as i32, height.0 as i32, PixelFormat::RGBA32)?))
    }

    pub fn load_bmp(path: &str) -> NativeResult<Surface> {
        Ok(Surface::from(SdlSurface::load_bmp(path)?))
    }

    // Any format SDL_image reads, told apart by its contents.
    pub fn load_image(path: &str) -> NativeResult<Surface> {
        Ok(Surface::from(sdl3_image::load(path)?))
    }

    // [[surface, delay_ms], ...] from an animated GIF, APNG, ANI, WebP or AVIF.
    pub fn load_animation(path: &str) -> NativeResult<Vec<(Surface, i64)>> {
        let animation = sdl3_image::load_animation(path)?;
        Ok(animation
            .frames
            .into_iter()
            .zip(animation.delays)
            .map(|(surface, delay)| (Surface::from(surface), delay as i64))
            .collect())
    }

    // Writes `surfaces` with `delays_ms` as an animation in the format the
    // extension names (GIF, APNG, ANI, WebP).
    pub fn save_animation(path: &str, surfaces: Vec<AnyObject>, delays_ms: Vec<Int>) -> NativeResult<()> {
        let delays = i32s(&delays_ms);
        let mut frames = Vec::with_capacity(surfaces.len());
        for object in &surfaces {
            let Ok(surface) = Surface::borrow_from(object) else {
                return arg_error("frames must be surfaces");
            };
            frames.push(surface.get().duplicate()?);
        }
        if frames.len() != delays.len() {
            return arg_error("one delay per frame");
        }
        let (w, h) = frames.first().map(|f| (f.width(), f.height())).unwrap_or((0, 0));
        let mut animation = sdl3_image::Animation { w, h, frames, delays };
        Ok(sdl3_image::save_animation(&mut animation, path)?)
    }
}

#[rubymethods]
impl Surface {
    pub fn width(&self) -> i64 {
        self.surface.width() as i64
    }

    pub fn height(&self) -> i64 {
        self.surface.height() as i64
    }

    pub fn pitch(&self) -> i64 {
        self.surface.pitch() as i64
    }

    pub fn format_name(&self) -> String {
        self.surface.format().name().to_owned()
    }

    pub fn save_bmp(&mut self, path: &str) -> NativeResult<()> {
        Ok(self.surface.save_bmp(path)?)
    }

    pub fn save_png(&mut self, path: &str) -> NativeResult<()> {
        Ok(self.surface.save_png(path)?)
    }

    // The format the extension names: PNG, JPEG, WebP, BMP, GIF, TGA, ICO, CUR.
    pub fn save(&mut self, path: &str) -> NativeResult<()> {
        Ok(sdl3_image::save(&mut self.surface, path)?)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn fill_rect(&mut self, x: OptInt, y: OptInt, w: OptInt, h: OptInt, r: Chan, g: Chan, b: Chan, a: Chan) -> NativeResult<()> {
        let rect = rect_of(x, y, w, h);
        let pixel = self.surface.map_rgba(r.0, g.0, b.0, a.0);
        Ok(self.surface.fill_rect(rect.as_ref(), pixel)?)
    }

    pub fn clear(&mut self, r: Num, g: Num, b: Num, a: Num) -> NativeResult<()> {
        Ok(self.surface.clear(r.0 as f32, g.0 as f32, b.0 as f32, a.0 as f32)?)
    }

    // dst.blit(src, sx, sy, sw, sh, dx, dy): the source rectangle may be nil.
    #[allow(clippy::too_many_arguments)]
    pub fn blit(&mut self, source: &AnyObject, sx: OptInt, sy: OptInt, sw: OptInt, sh: OptInt, dx: Int, dy: Int) -> NativeResult<()> {
        let mut source = other_surface(source)?;
        let srcrect = rect_of(sx, sy, sw, sh);
        let dstrect = Rect::new(dx.0 as i32, dy.0 as i32, 0, 0);
        Ok(source.get_mut().blit(srcrect.as_ref(), &mut self.surface, Some(&dstrect))?)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn blit_scaled(&mut self, source: &AnyObject, sx: OptInt, sy: OptInt, sw: OptInt, sh: OptInt, dx: OptInt, dy: OptInt, dw: OptInt, dh: OptInt, mode: Int) -> NativeResult<()> {
        let mut source = other_surface(source)?;
        let srcrect = rect_of(sx, sy, sw, sh);
        let dstrect = rect_of(dx, dy, dw, dh);
        let mode = scale_mode_of(mode)?;
        Ok(source.get_mut().blit_scaled(srcrect.as_ref(), &mut self.surface, dstrect.as_ref(), mode)?)
    }

    pub fn get_pixel(&self, x: Int, y: Int) -> NativeResult<(i64, i64, i64, i64)> {
        Ok(channels(self.surface.read_pixel(x.0 as i32, y.0 as i32)?))
    }

    pub fn set_pixel(&mut self, x: Int, y: Int, r: Chan, g: Chan, b: Chan, a: Chan) -> NativeResult<()> {
        Ok(self.surface.write_pixel(x.0 as i32, y.0 as i32, color_of(r, g, b, a))?)
    }

    // `r` nil clears the key.
    pub fn set_color_key(&mut self, r: OptInt, g: Chan, b: Chan) -> NativeResult<()> {
        let key = r.0.map(|r| self.surface.map_rgb(r.clamp(0, 255) as u8, g.0, b.0));
        Ok(self.surface.set_color_key(key)?)
    }

    #[ruby(name = "alpha_mod=")]
    pub fn set_alpha_mod(&mut self, alpha: Chan) {
        self.surface.set_alpha_mod(alpha.0);
    }

    pub fn alpha_mod(&self) -> i64 {
        self.surface.alpha_mod() as i64
    }

    pub fn set_color_mod(&mut self, r: Chan, g: Chan, b: Chan) {
        self.surface.set_color_mod(r.0, g.0, b.0);
    }

    #[ruby(name = "blend_mode=")]
    pub fn set_blend_mode(&mut self, mode: Int) -> NativeResult<()> {
        Ok(self.surface.set_blend_mode(blend_mode_of(mode))?)
    }

    pub fn blend_mode(&self) -> i64 {
        self.surface.blend_mode().0 as i64
    }

    pub fn set_clip_rect(&mut self, x: OptInt, y: OptInt, w: OptInt, h: OptInt) -> bool {
        let rect = rect_of(x, y, w, h);
        self.surface.set_clip_rect(rect.as_ref())
    }

    pub fn duplicate(&self) -> NativeResult<Surface> {
        Ok(Surface::from(self.surface.duplicate()?))
    }

    pub fn scale(&self, width: Int, height: Int, mode: Int) -> NativeResult<Surface> {
        let scaled = self.surface.scale(width.0 as i32, height.0 as i32, scale_mode_of(mode)?)?;
        Ok(Surface::from(scaled))
    }

    pub fn rotate(&mut self, angle: Num) -> NativeResult<Surface> {
        Ok(Surface::from(self.surface.rotate(angle.0 as f32)?))
    }

    pub fn flip(&mut self, mode: Int) -> NativeResult<()> {
        Ok(self.surface.flip(flip_mode_of(mode)?)?)
    }

    // The raw pixel bytes (RGBA32, `pitch` bytes per row) as a binary String.
    pub fn pixels(&self) -> Option<Bytes> {
        self.surface.pixels().map(|bytes| Bytes(bytes.to_vec()))
    }

    #[ruby(name = "pixels=")]
    pub fn write_pixels(&mut self, bytes: &Bytes) -> NativeResult<()> {
        let Some(pixels) = self.surface.pixels_mut() else {
            return arg_error("this surface has no pixel buffer");
        };
        if bytes.0.len() != pixels.len() {
            return arg_error(&format!("expected {} bytes of pixel data, got {}", pixels.len(), bytes.0.len()));
        }
        pixels.copy_from_slice(&bytes.0);
        Ok(())
    }
}

pub fn define() {
    functions::define_ruby();
    Surface::define_ruby();
}
