//! `Rbgame::Native::Renderer` and `Rbgame::Native::Texture`.
//!
//! Textures are handles owned by their renderer; `Renderer#destroy_texture`
//! frees one early, and the renderer frees the rest when Ruby collects it.

use rutie::derive::RubyClass;
use rutie::{rubyclass, rubymethods, rubymodule, AnyObject};
use sdl3::render::{LogicalPresentation, Renderer as SdlRenderer, Texture as SdlTexture, TextureAccess, Vertex};
use sdl3::video::{FColor, FPoint, PixelFormat};

use crate::support::{arg_error, fpoints_of, frect_of, frects_of, i32s, rect_of, Chan, Int, NativeResult, Num, OptInt, OptNum};
use crate::surface::{blend_mode_of, flip_mode_of, scale_mode_of, Surface};

/// Instances come only from Rust (`Native.create_renderer`), never from
/// `Renderer.new`.
#[rubyclass(path = "Rbgame::Native::Renderer", allocator = false)]
pub struct Renderer {
    renderer: SdlRenderer,
}

/// A texture handle with its size; instances come only from the renderer.
#[rubyclass(path = "Rbgame::Native::Texture", allocator = false)]
pub struct Texture {
    texture: SdlTexture,
    width: f32,
    height: f32,
}

impl Texture {
    fn of(renderer: &SdlRenderer, texture: SdlTexture) -> NativeResult<Texture> {
        let (width, height) = renderer.texture_size(texture)?;
        Ok(Texture { texture, width, height })
    }
}

fn logical_presentation_of(value: Int) -> NativeResult<LogicalPresentation> {
    match value.0 {
        0 => Ok(LogicalPresentation::Disabled),
        1 => Ok(LogicalPresentation::Stretch),
        2 => Ok(LogicalPresentation::Letterbox),
        3 => Ok(LogicalPresentation::Overscan),
        4 => Ok(LogicalPresentation::IntegerScale),
        other => arg_error(&format!("unknown logical presentation mode {other}")),
    }
}

fn logical_presentation_code(mode: LogicalPresentation) -> i64 {
    match mode {
        LogicalPresentation::Disabled => 0,
        LogicalPresentation::Stretch => 1,
        LogicalPresentation::Letterbox => 2,
        LogicalPresentation::Overscan => 3,
        LogicalPresentation::IntegerScale => 4,
    }
}

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use sdl3::render::Renderer as SdlRenderer;

    use super::Renderer;
    use crate::support::NativeResult;
    use crate::surface::Surface;
    use crate::window::Window;

    pub fn create_renderer(window: &Window, driver: Option<String>) -> NativeResult<Renderer> {
        let renderer = SdlRenderer::for_window(window.get()?, driver.as_deref())?;
        Ok(Renderer { renderer })
    }

    // A renderer drawing into a private copy of `surface`; read the result
    // back with `read_pixels`.
    pub fn create_software_renderer(surface: &Surface) -> NativeResult<Renderer> {
        let renderer = SdlRenderer::software(surface.get().duplicate()?)?;
        Ok(Renderer { renderer })
    }
}

#[rubymethods]
impl Renderer {
    pub fn name(&self) -> String {
        self.renderer.name().to_owned()
    }

    pub fn output_size(&mut self) -> NativeResult<(i64, i64)> {
        let (w, h) = self.renderer.output_size()?;
        Ok((w as i64, h as i64))
    }

    pub fn set_draw_color(&mut self, r: Chan, g: Chan, b: Chan, a: Chan) {
        self.renderer.set_draw_color(r.0, g.0, b.0, a.0);
    }

    pub fn draw_color(&self) -> (i64, i64, i64, i64) {
        let (r, g, b, a) = self.renderer.draw_color();
        (r as i64, g as i64, b as i64, a as i64)
    }

    #[ruby(name = "blend_mode=")]
    pub fn set_blend_mode(&mut self, mode: Int) -> NativeResult<()> {
        Ok(self.renderer.set_draw_blend_mode(blend_mode_of(mode))?)
    }

    pub fn blend_mode(&self) -> i64 {
        self.renderer.draw_blend_mode().0 as i64
    }

    pub fn clear(&mut self) -> NativeResult<()> {
        Ok(self.renderer.clear()?)
    }

    pub fn present(&mut self) -> NativeResult<()> {
        Ok(self.renderer.present()?)
    }

    pub fn point(&mut self, x: Num, y: Num) -> NativeResult<()> {
        Ok(self.renderer.render_point(x.0 as f32, y.0 as f32)?)
    }

    pub fn points(&mut self, points: Vec<Num>) -> NativeResult<()> {
        Ok(self.renderer.render_points(&fpoints_of(&points)?)?)
    }

    pub fn line(&mut self, x1: Num, y1: Num, x2: Num, y2: Num) -> NativeResult<()> {
        Ok(self.renderer.render_line(x1.0 as f32, y1.0 as f32, x2.0 as f32, y2.0 as f32)?)
    }

    pub fn lines(&mut self, points: Vec<Num>) -> NativeResult<()> {
        Ok(self.renderer.render_lines(&fpoints_of(&points)?)?)
    }

    pub fn rect(&mut self, x: OptNum, y: OptNum, w: OptNum, h: OptNum) -> NativeResult<()> {
        Ok(self.renderer.render_rect(frect_of(x, y, w, h).as_ref())?)
    }

    pub fn rects(&mut self, rects: Vec<Num>) -> NativeResult<()> {
        Ok(self.renderer.render_rects(&frects_of(&rects)?)?)
    }

    pub fn fill_rect(&mut self, x: OptNum, y: OptNum, w: OptNum, h: OptNum) -> NativeResult<()> {
        Ok(self.renderer.render_fill_rect(frect_of(x, y, w, h).as_ref())?)
    }

    pub fn fill_rects(&mut self, rects: Vec<Num>) -> NativeResult<()> {
        Ok(self.renderer.render_fill_rects(&frects_of(&rects)?)?)
    }

    // Triangles from a flat vertex list: x, y, r, g, b, a (0-255), u, v per
    // vertex. `indices` nil draws them in order.
    pub fn geometry(&mut self, texture: &AnyObject, vertices: Vec<Num>, indices: Option<Vec<Int>>) -> NativeResult<()> {
        let texture = if texture.is_nil() { None } else { Some(Texture::borrow_from(texture)?) };
        if !vertices.len().is_multiple_of(8) {
            return arg_error("vertices must hold 8 numbers per vertex: x, y, r, g, b, a, u, v");
        }
        let vertices: Vec<Vertex> = vertices
            .chunks(8)
            .map(|v| Vertex {
                position: FPoint::new(v[0].0 as f32, v[1].0 as f32),
                color: FColor::new(v[2].0 as f32 / 255.0, v[3].0 as f32 / 255.0, v[4].0 as f32 / 255.0, v[5].0 as f32 / 255.0),
                tex_coord: FPoint::new(v[6].0 as f32, v[7].0 as f32),
            })
            .collect();
        let indices = indices.map(|indices| i32s(&indices));
        Ok(self.renderer.render_geometry(texture.as_ref().map(|t| t.texture), &vertices, indices.as_deref())?)
    }

    pub fn set_clip_rect(&mut self, x: OptInt, y: OptInt, w: OptInt, h: OptInt) -> NativeResult<()> {
        Ok(self.renderer.set_clip_rect(rect_of(x, y, w, h).as_ref())?)
    }

    pub fn set_viewport(&mut self, x: OptInt, y: OptInt, w: OptInt, h: OptInt) -> NativeResult<()> {
        Ok(self.renderer.set_viewport(rect_of(x, y, w, h).as_ref())?)
    }

    pub fn set_scale(&mut self, sx: Num, sy: Num) -> NativeResult<()> {
        Ok(self.renderer.set_scale(sx.0 as f32, sy.0 as f32)?)
    }

    pub fn scale(&self) -> (f64, f64) {
        let (sx, sy) = self.renderer.scale();
        (sx as f64, sy as f64)
    }

    pub fn set_logical_presentation(&mut self, w: Int, h: Int, mode: Int) -> NativeResult<()> {
        Ok(self.renderer.set_logical_presentation(w.0 as i32, h.0 as i32, logical_presentation_of(mode)?)?)
    }

    pub fn logical_presentation(&self) -> (i64, i64, i64) {
        let (w, h, mode) = self.renderer.logical_presentation();
        (w as i64, h as i64, logical_presentation_code(mode))
    }

    pub fn coordinates_from_window(&self, x: Num, y: Num) -> (f64, f64) {
        let (rx, ry) = self.renderer.coordinates_from_window(x.0 as f32, y.0 as f32);
        (rx as f64, ry as f64)
    }

    #[ruby(name = "vsync=")]
    pub fn set_vsync(&mut self, vsync: Int) -> NativeResult<()> {
        Ok(self.renderer.set_vsync(vsync.0 as i32)?)
    }

    pub fn vsync(&self) -> i64 {
        self.renderer.vsync() as i64
    }

    // SDL's built-in 8x8 debug font.
    pub fn debug_text(&mut self, x: Num, y: Num, text: &str) -> NativeResult<()> {
        Ok(self.renderer.render_debug_text(x.0 as f32, y.0 as f32, text)?)
    }

    pub fn read_pixels(&mut self, x: OptInt, y: OptInt, w: OptInt, h: OptInt) -> NativeResult<Surface> {
        let pixels = self.renderer.read_pixels(rect_of(x, y, w, h).as_ref())?;
        Ok(Surface::from(pixels.convert(PixelFormat::RGBA32)?))
    }

    pub fn create_texture_from_surface(&mut self, source: &mut Surface) -> NativeResult<Texture> {
        let texture = self.renderer.create_texture_from_surface(source.get_mut())?;
        Texture::of(&self.renderer, texture)
    }

    // An empty texture usable as a render target.
    pub fn create_target_texture(&mut self, w: Int, h: Int) -> NativeResult<Texture> {
        let texture = self.renderer.create_texture(PixelFormat::RGBA32, TextureAccess::Target, w.0 as i32, h.0 as i32)?;
        Texture::of(&self.renderer, texture)
    }

    #[ruby(name = "render_target=")]
    pub fn set_render_target(&mut self, texture: Option<&Texture>) -> NativeResult<()> {
        Ok(self.renderer.set_render_target(texture.map(|t| t.texture))?)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn render_texture(&mut self, texture: &Texture, sx: OptNum, sy: OptNum, sw: OptNum, sh: OptNum, dx: OptNum, dy: OptNum, dw: OptNum, dh: OptNum) -> NativeResult<()> {
        let src = frect_of(sx, sy, sw, sh);
        let dst = frect_of(dx, dy, dw, dh);
        Ok(self.renderer.render_texture(texture.texture, src.as_ref(), dst.as_ref())?)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn render_texture_rotated(&mut self, texture: &Texture, sx: OptNum, sy: OptNum, sw: OptNum, sh: OptNum, dx: OptNum, dy: OptNum, dw: OptNum, dh: OptNum, angle: Num, cx: OptNum, cy: OptNum, flip: Int) -> NativeResult<()> {
        let src = frect_of(sx, sy, sw, sh);
        let dst = frect_of(dx, dy, dw, dh);
        let center = cx.0.map(|cx| FPoint::new(cx as f32, cy.0.unwrap_or(0.0) as f32));
        Ok(self.renderer.render_texture_rotated(texture.texture, src.as_ref(), dst.as_ref(), angle.0, center.as_ref(), flip_mode_of(flip)?)?)
    }

    pub fn set_texture_alpha_mod(&mut self, texture: &Texture, alpha: Chan) -> NativeResult<()> {
        Ok(self.renderer.set_texture_alpha_mod(texture.texture, alpha.0)?)
    }

    pub fn set_texture_color_mod(&mut self, texture: &Texture, r: Chan, g: Chan, b: Chan) -> NativeResult<()> {
        Ok(self.renderer.set_texture_color_mod(texture.texture, r.0, g.0, b.0)?)
    }

    pub fn set_texture_blend_mode(&mut self, texture: &Texture, mode: Int) -> NativeResult<()> {
        Ok(self.renderer.set_texture_blend_mode(texture.texture, blend_mode_of(mode))?)
    }

    pub fn set_texture_scale_mode(&mut self, texture: &Texture, mode: Int) -> NativeResult<()> {
        Ok(self.renderer.set_texture_scale_mode(texture.texture, scale_mode_of(mode)?)?)
    }

    pub fn destroy_texture(&mut self, texture: &Texture) {
        self.renderer.destroy_texture(texture.texture);
    }
}

#[rubymethods]
impl Texture {
    pub fn width(&self) -> f64 {
        self.width as f64
    }

    pub fn height(&self) -> f64 {
        self.height as f64
    }
}

pub fn define() {
    functions::define_ruby();
    Renderer::define_ruby();
    Texture::define_ruby();
}
