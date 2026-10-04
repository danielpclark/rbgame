//! `Rbgame::Native::Renderer` and `Rbgame::Native::Texture`.
//!
//! Textures are handles owned by their renderer; `Texture#destroy` frees one
//! early, and the renderer frees the rest when Ruby collects it.

use rutie::{AnyObject, Array, Fixnum, Float, Module, NilClass, Object, RString};
use sdl3::render::{LogicalPresentation, Renderer, Texture, TextureAccess, Vertex};
use sdl3::video::{FColor, FPoint, PixelFormat};

use crate::support::{
    arg, f32_of, f32s_of, f64_of, fpoints_of, frects_of, i32_of, i32s_of, i64_of, is_nil, native,
    opt_f32_of, opt_frect_of, opt_rect_of, opt_str_of, pair, raise_arg, str_of, u8_of, OrRaise,
};
use crate::surface::{self, blend_mode_of, flip_mode_of, scale_mode_of, RbSurface};
use crate::window::RbWindow;

pub struct RendererBox {
    renderer: Renderer,
}

wrappable_struct!(RendererBox, RendererWrapper, RENDERER_WRAPPER);
native_class!(RbRenderer, "Renderer");

pub struct TextureBox {
    texture: Texture,
    width: f32,
    height: f32,
}

wrappable_struct!(TextureBox, TextureWrapper, TEXTURE_WRAPPER);
native_class!(RbTexture, "Texture");

impl RbRenderer {
    fn renderer(&mut self) -> &mut Renderer {
        &mut self.get_data_mut(&*RENDERER_WRAPPER).renderer
    }
}

impl RbTexture {
    fn handle(&self) -> Texture {
        self.get_data(&*TEXTURE_WRAPPER).texture
    }
}

fn wrap_renderer(renderer: Renderer) -> AnyObject {
    native()
        .get_nested_class("Renderer")
        .wrap_data(RendererBox { renderer }, &*RENDERER_WRAPPER)
}

fn wrap_texture(renderer: &Renderer, texture: Texture) -> AnyObject {
    let (width, height) = renderer.texture_size(texture).or_raise();
    native()
        .get_nested_class("Texture")
        .wrap_data(TextureBox { texture, width, height }, &*TEXTURE_WRAPPER)
}

fn texture_of(value: crate::support::Arg<RbTexture>) -> Texture {
    arg(value).handle()
}

fn opt_texture_of(value: crate::support::Arg<AnyObject>) -> Option<Texture> {
    let object = arg(value);
    if is_nil(&object) {
        None
    } else {
        Some(texture_of(object.try_convert_to::<RbTexture>()))
    }
}

fn logical_presentation_of(value: crate::support::Arg<AnyObject>) -> LogicalPresentation {
    match i64_of(value, "presentation mode") {
        0 => LogicalPresentation::Disabled,
        1 => LogicalPresentation::Stretch,
        2 => LogicalPresentation::Letterbox,
        3 => LogicalPresentation::Overscan,
        4 => LogicalPresentation::IntegerScale,
        other => raise_arg(&format!("unknown logical presentation mode {other}")),
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

methods!(
    AnyObject,
    _rtself,

    fn rend_create(window: RbWindow, driver: AnyObject) -> AnyObject {
        let window = arg(window);
        let driver = opt_str_of(driver, "driver");
        let renderer = Renderer::for_window(window.window(), driver.as_deref()).or_raise();
        wrap_renderer(renderer)
    }

    // A renderer drawing into a private copy of `surface`; read the result
    // back with `read_pixels`.
    fn rend_create_software(surface: RbSurface) -> AnyObject {
        let surface = arg(surface);
        let renderer = Renderer::software(surface.surface().duplicate().or_raise()).or_raise();
        wrap_renderer(renderer)
    }
);

methods!(
    RbRenderer,
    rtself,

    fn rend_name() -> RString {
        RString::new_utf8(rtself.renderer().name())
    }

    fn rend_output_size() -> Array {
        let (w, h) = rtself.renderer().output_size().or_raise();
        pair(w as i64, h as i64)
    }

    fn rend_set_draw_color(r: AnyObject, g: AnyObject, b: AnyObject, a: AnyObject) -> NilClass {
        rtself
            .renderer()
            .set_draw_color(u8_of(r, "r"), u8_of(g, "g"), u8_of(b, "b"), u8_of(a, "a"));
        NilClass::new()
    }

    fn rend_draw_color() -> Array {
        let (r, g, b, a) = rtself.renderer().draw_color();
        let mut array = Array::with_capacity(4);
        for channel in [r, g, b, a] {
            array.push(Fixnum::new(channel as i64));
        }
        array
    }

    fn rend_set_blend_mode(mode: AnyObject) -> NilClass {
        rtself.renderer().set_draw_blend_mode(blend_mode_of(mode)).or_raise();
        NilClass::new()
    }

    fn rend_blend_mode() -> Fixnum {
        Fixnum::new(rtself.renderer().draw_blend_mode().0 as i64)
    }

    fn rend_clear() -> NilClass {
        rtself.renderer().clear().or_raise();
        NilClass::new()
    }

    fn rend_present() -> NilClass {
        rtself.renderer().present().or_raise();
        NilClass::new()
    }

    fn rend_point(x: AnyObject, y: AnyObject) -> NilClass {
        rtself.renderer().render_point(f32_of(x, "x"), f32_of(y, "y")).or_raise();
        NilClass::new()
    }

    fn rend_points(points: Array) -> NilClass {
        let points = fpoints_of(points, "points");
        rtself.renderer().render_points(&points).or_raise();
        NilClass::new()
    }

    fn rend_line(x1: AnyObject, y1: AnyObject, x2: AnyObject, y2: AnyObject) -> NilClass {
        rtself
            .renderer()
            .render_line(f32_of(x1, "x1"), f32_of(y1, "y1"), f32_of(x2, "x2"), f32_of(y2, "y2"))
            .or_raise();
        NilClass::new()
    }

    fn rend_lines(points: Array) -> NilClass {
        let points = fpoints_of(points, "points");
        rtself.renderer().render_lines(&points).or_raise();
        NilClass::new()
    }

    fn rend_rect(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject) -> NilClass {
        let rect = opt_frect_of(x, y, w, h);
        rtself.renderer().render_rect(rect.as_ref()).or_raise();
        NilClass::new()
    }

    fn rend_rects(rects: Array) -> NilClass {
        let rects = frects_of(rects, "rects");
        rtself.renderer().render_rects(&rects).or_raise();
        NilClass::new()
    }

    fn rend_fill_rect(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject) -> NilClass {
        let rect = opt_frect_of(x, y, w, h);
        rtself.renderer().render_fill_rect(rect.as_ref()).or_raise();
        NilClass::new()
    }

    fn rend_fill_rects(rects: Array) -> NilClass {
        let rects = frects_of(rects, "rects");
        rtself.renderer().render_fill_rects(&rects).or_raise();
        NilClass::new()
    }

    // Triangles from a flat vertex list: x, y, r, g, b, a (0-255), u, v per
    // vertex. `indices` nil draws them in order.
    fn rend_geometry(texture: AnyObject, vertices: Array, indices: AnyObject) -> NilClass {
        let texture = opt_texture_of(texture);
        let floats = f32s_of(vertices, "vertices");
        if !floats.len().is_multiple_of(8) {
            raise_arg("vertices must hold 8 numbers per vertex: x, y, r, g, b, a, u, v");
        }
        let vertices: Vec<Vertex> = floats
            .chunks(8)
            .map(|v| Vertex {
                position: FPoint::new(v[0], v[1]),
                color: FColor::new(v[2] / 255.0, v[3] / 255.0, v[4] / 255.0, v[5] / 255.0),
                tex_coord: FPoint::new(v[6], v[7]),
            })
            .collect();
        let indices = {
            let object = arg(indices);
            if is_nil(&object) {
                None
            } else {
                Some(i32s_of(object.try_convert_to::<Array>(), "indices"))
            }
        };
        rtself
            .renderer()
            .render_geometry(texture, &vertices, indices.as_deref())
            .or_raise();
        NilClass::new()
    }

    fn rend_set_clip_rect(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject) -> NilClass {
        let rect = opt_rect_of(x, y, w, h);
        rtself.renderer().set_clip_rect(rect.as_ref()).or_raise();
        NilClass::new()
    }

    fn rend_set_viewport(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject) -> NilClass {
        let rect = opt_rect_of(x, y, w, h);
        rtself.renderer().set_viewport(rect.as_ref()).or_raise();
        NilClass::new()
    }

    fn rend_set_scale(sx: AnyObject, sy: AnyObject) -> NilClass {
        rtself.renderer().set_scale(f32_of(sx, "sx"), f32_of(sy, "sy")).or_raise();
        NilClass::new()
    }

    fn rend_scale() -> Array {
        let (sx, sy) = rtself.renderer().scale();
        crate::support::fpair(sx as f64, sy as f64)
    }

    fn rend_set_logical_presentation(w: AnyObject, h: AnyObject, mode: AnyObject) -> NilClass {
        rtself
            .renderer()
            .set_logical_presentation(i32_of(w, "w"), i32_of(h, "h"), logical_presentation_of(mode))
            .or_raise();
        NilClass::new()
    }

    fn rend_logical_presentation() -> Array {
        let (w, h, mode) = rtself.renderer().logical_presentation();
        let mut array = Array::with_capacity(3);
        array.push(Fixnum::new(w as i64));
        array.push(Fixnum::new(h as i64));
        array.push(Fixnum::new(logical_presentation_code(mode)));
        array
    }

    fn rend_coordinates_from_window(x: AnyObject, y: AnyObject) -> Array {
        let (rx, ry) = rtself.renderer().coordinates_from_window(f32_of(x, "x"), f32_of(y, "y"));
        crate::support::fpair(rx as f64, ry as f64)
    }

    fn rend_set_vsync(vsync: AnyObject) -> NilClass {
        rtself.renderer().set_vsync(i32_of(vsync, "vsync")).or_raise();
        NilClass::new()
    }

    fn rend_vsync() -> Fixnum {
        Fixnum::new(rtself.renderer().vsync() as i64)
    }

    // SDL's built-in 8x8 debug font.
    fn rend_debug_text(x: AnyObject, y: AnyObject, text: RString) -> NilClass {
        rtself
            .renderer()
            .render_debug_text(f32_of(x, "x"), f32_of(y, "y"), &str_of(text))
            .or_raise();
        NilClass::new()
    }

    fn rend_read_pixels(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject) -> AnyObject {
        let rect = opt_rect_of(x, y, w, h);
        let pixels = rtself.renderer().read_pixels(rect.as_ref()).or_raise();
        let converted = pixels.convert(PixelFormat::RGBA32).or_raise();
        surface::wrap(converted)
    }

    fn rend_create_texture_from_surface(source: RbSurface) -> AnyObject {
        let mut source = arg(source);
        let renderer = rtself.renderer();
        let texture = renderer.create_texture_from_surface(source.surface_mut()).or_raise();
        wrap_texture(renderer, texture)
    }

    // An empty texture usable as a render target.
    fn rend_create_target_texture(w: AnyObject, h: AnyObject) -> AnyObject {
        let renderer = rtself.renderer();
        let texture = renderer
            .create_texture(PixelFormat::RGBA32, TextureAccess::Target, i32_of(w, "w"), i32_of(h, "h"))
            .or_raise();
        wrap_texture(renderer, texture)
    }

    fn rend_set_render_target(texture: AnyObject) -> NilClass {
        let texture = opt_texture_of(texture);
        rtself.renderer().set_render_target(texture).or_raise();
        NilClass::new()
    }

    fn rend_render_texture(texture: RbTexture, sx: AnyObject, sy: AnyObject, sw: AnyObject, sh: AnyObject, dx: AnyObject, dy: AnyObject, dw: AnyObject, dh: AnyObject) -> NilClass {
        let texture = texture_of(texture);
        let src = opt_frect_of(sx, sy, sw, sh);
        let dst = opt_frect_of(dx, dy, dw, dh);
        rtself.renderer().render_texture(texture, src.as_ref(), dst.as_ref()).or_raise();
        NilClass::new()
    }

    fn rend_render_texture_rotated(texture: RbTexture, sx: AnyObject, sy: AnyObject, sw: AnyObject, sh: AnyObject, dx: AnyObject, dy: AnyObject, dw: AnyObject, dh: AnyObject, angle: AnyObject, cx: AnyObject, cy: AnyObject, flip: AnyObject) -> NilClass {
        let texture = texture_of(texture);
        let src = opt_frect_of(sx, sy, sw, sh);
        let dst = opt_frect_of(dx, dy, dw, dh);
        let center = opt_f32_of(cx, "cx").map(|cx| FPoint::new(cx, f32_of(cy, "cy")));
        rtself
            .renderer()
            .render_texture_rotated(texture, src.as_ref(), dst.as_ref(), f64_of(angle, "angle"), center.as_ref(), flip_mode_of(flip))
            .or_raise();
        NilClass::new()
    }

    fn rend_set_texture_alpha_mod(texture: RbTexture, alpha: AnyObject) -> NilClass {
        let texture = texture_of(texture);
        rtself.renderer().set_texture_alpha_mod(texture, u8_of(alpha, "alpha")).or_raise();
        NilClass::new()
    }

    fn rend_set_texture_color_mod(texture: RbTexture, r: AnyObject, g: AnyObject, b: AnyObject) -> NilClass {
        let texture = texture_of(texture);
        rtself
            .renderer()
            .set_texture_color_mod(texture, u8_of(r, "r"), u8_of(g, "g"), u8_of(b, "b"))
            .or_raise();
        NilClass::new()
    }

    fn rend_set_texture_blend_mode(texture: RbTexture, mode: AnyObject) -> NilClass {
        let texture = texture_of(texture);
        rtself.renderer().set_texture_blend_mode(texture, blend_mode_of(mode)).or_raise();
        NilClass::new()
    }

    fn rend_set_texture_scale_mode(texture: RbTexture, mode: AnyObject) -> NilClass {
        let texture = texture_of(texture);
        rtself.renderer().set_texture_scale_mode(texture, scale_mode_of(mode)).or_raise();
        NilClass::new()
    }

    fn rend_destroy_texture(texture: RbTexture) -> NilClass {
        let texture = texture_of(texture);
        rtself.renderer().destroy_texture(texture);
        NilClass::new()
    }
);

methods!(
    RbTexture,
    rtself,

    fn tex_width() -> Float {
        Float::new(rtself.get_data(&*TEXTURE_WRAPPER).width as f64)
    }

    fn tex_height() -> Float {
        Float::new(rtself.get_data(&*TEXTURE_WRAPPER).height as f64)
    }
);

pub fn define(native: &mut Module) {
    native.def_self("create_renderer", rend_create);
    native.def_self("create_software_renderer", rend_create_software);

    let mut klass = native.define_nested_class("Renderer", None);
    // Instances come only from Rust (`wrap_data`), never from `Renderer.new`.
    klass.undef_alloc_func();
    klass.define(|klass| {
        klass.def("name", rend_name);
        klass.def("output_size", rend_output_size);
        klass.def("set_draw_color", rend_set_draw_color);
        klass.def("draw_color", rend_draw_color);
        klass.def("blend_mode=", rend_set_blend_mode);
        klass.def("blend_mode", rend_blend_mode);
        klass.def("clear", rend_clear);
        klass.def("present", rend_present);
        klass.def("point", rend_point);
        klass.def("points", rend_points);
        klass.def("line", rend_line);
        klass.def("lines", rend_lines);
        klass.def("rect", rend_rect);
        klass.def("rects", rend_rects);
        klass.def("fill_rect", rend_fill_rect);
        klass.def("fill_rects", rend_fill_rects);
        klass.def("geometry", rend_geometry);
        klass.def("set_clip_rect", rend_set_clip_rect);
        klass.def("set_viewport", rend_set_viewport);
        klass.def("set_scale", rend_set_scale);
        klass.def("scale", rend_scale);
        klass.def("set_logical_presentation", rend_set_logical_presentation);
        klass.def("logical_presentation", rend_logical_presentation);
        klass.def("coordinates_from_window", rend_coordinates_from_window);
        klass.def("vsync=", rend_set_vsync);
        klass.def("vsync", rend_vsync);
        klass.def("debug_text", rend_debug_text);
        klass.def("read_pixels", rend_read_pixels);
        klass.def("create_texture_from_surface", rend_create_texture_from_surface);
        klass.def("create_target_texture", rend_create_target_texture);
        klass.def("render_target=", rend_set_render_target);
        klass.def("render_texture", rend_render_texture);
        klass.def("render_texture_rotated", rend_render_texture_rotated);
        klass.def("set_texture_alpha_mod", rend_set_texture_alpha_mod);
        klass.def("set_texture_color_mod", rend_set_texture_color_mod);
        klass.def("set_texture_blend_mode", rend_set_texture_blend_mode);
        klass.def("set_texture_scale_mode", rend_set_texture_scale_mode);
        klass.def("destroy_texture", rend_destroy_texture);
    });

    let mut klass = native.define_nested_class("Texture", None);
    // Instances come only from Rust (`wrap_data`), never from `Texture.new`.
    klass.undef_alloc_func();
    klass.define(|klass| {
        klass.def("width", tex_width);
        klass.def("height", tex_height);
    });
}
