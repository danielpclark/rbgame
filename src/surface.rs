//! `Rbgame::Native::Surface`: a CPU-side image.

use rutie::{AnyObject, Array, Boolean, Encoding, Fixnum, Module, NilClass, Object, RString};
use sdl3::video::{BlendMode, Color, FlipMode, PixelFormat, Rect, ScaleMode, Surface};

use crate::support::{
    arg, f32_of, i32_of, i64_of, is_nil, native, opt_rect_of, raise_arg, str_of, u8_of, OrRaise,
};

pub struct SurfaceBox {
    surface: Surface<'static>,
}

wrappable_struct!(SurfaceBox, SurfaceWrapper, SURFACE_WRAPPER);
native_class!(RbSurface, "Surface");

pub fn wrap(surface: Surface<'static>) -> AnyObject {
    native()
        .get_nested_class("Surface")
        .wrap_data(SurfaceBox { surface }, &*SURFACE_WRAPPER)
}

impl RbSurface {
    pub fn surface(&self) -> &Surface<'static> {
        &self.get_data(&*SURFACE_WRAPPER).surface
    }

    pub fn surface_mut(&mut self) -> &mut Surface<'static> {
        &mut self.get_data_mut(&*SURFACE_WRAPPER).surface
    }
}

pub fn blend_mode_of(value: crate::support::Arg<AnyObject>) -> BlendMode {
    BlendMode(i64_of(value, "blend mode") as u32)
}

pub fn scale_mode_of(value: crate::support::Arg<AnyObject>) -> ScaleMode {
    match i64_of(value, "scale mode") {
        0 => ScaleMode::Nearest,
        1 => ScaleMode::Linear,
        2 => ScaleMode::PixelArt,
        other => raise_arg(&format!("unknown scale mode {other}")),
    }
}

pub fn flip_mode_of(value: crate::support::Arg<AnyObject>) -> FlipMode {
    match i64_of(value, "flip mode") {
        0 => FlipMode::None,
        1 => FlipMode::Horizontal,
        2 => FlipMode::Vertical,
        other => raise_arg(&format!("unknown flip mode {other}")),
    }
}

fn color_array(color: Color) -> Array {
    let mut array = Array::with_capacity(4);
    for channel in [color.r, color.g, color.b, color.a] {
        array.push(Fixnum::new(channel as i64));
    }
    array
}

methods!(
    AnyObject,
    _rtself,

    fn surf_create(width: AnyObject, height: AnyObject) -> AnyObject {
        let surface = Surface::new(i32_of(width, "width"), i32_of(height, "height"), PixelFormat::RGBA32).or_raise();
        wrap(surface)
    }

    fn surf_load_bmp(path: RString) -> AnyObject {
        wrap(Surface::load_bmp(str_of(path)).or_raise())
    }

    // BMP, PNG or JPEG, told apart by their contents.
    fn surf_load_image(path: RString) -> AnyObject {
        wrap(Surface::load(str_of(path)).or_raise())
    }
);

methods!(
    RbSurface,
    rtself,

    fn surf_width() -> Fixnum {
        Fixnum::new(rtself.surface().width() as i64)
    }

    fn surf_height() -> Fixnum {
        Fixnum::new(rtself.surface().height() as i64)
    }

    fn surf_pitch() -> Fixnum {
        Fixnum::new(rtself.surface().pitch() as i64)
    }

    fn surf_format_name() -> RString {
        RString::new_utf8(rtself.surface().format().name())
    }

    fn surf_save_bmp(path: RString) -> NilClass {
        rtself.surface_mut().save_bmp(str_of(path)).or_raise();
        NilClass::new()
    }

    fn surf_save_png(path: RString) -> NilClass {
        rtself.surface_mut().save_png(str_of(path)).or_raise();
        NilClass::new()
    }

    fn surf_fill_rect(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject, r: AnyObject, g: AnyObject, b: AnyObject, a: AnyObject) -> NilClass {
        let rect = opt_rect_of(x, y, w, h);
        let surface = rtself.surface_mut();
        let pixel = surface.map_rgba(u8_of(r, "r"), u8_of(g, "g"), u8_of(b, "b"), u8_of(a, "a"));
        surface.fill_rect(rect.as_ref(), pixel).or_raise();
        NilClass::new()
    }

    fn surf_clear(r: AnyObject, g: AnyObject, b: AnyObject, a: AnyObject) -> NilClass {
        rtself
            .surface_mut()
            .clear(f32_of(r, "r"), f32_of(g, "g"), f32_of(b, "b"), f32_of(a, "a"))
            .or_raise();
        NilClass::new()
    }

    // dst.blit(src, sx, sy, sw, sh, dx, dy): the source rectangle may be nil.
    fn surf_blit(source: RbSurface, sx: AnyObject, sy: AnyObject, sw: AnyObject, sh: AnyObject, dx: AnyObject, dy: AnyObject) -> NilClass {
        let mut source = arg(source);
        if source.equals(&rtself) {
            raise_arg("a surface cannot be blitted onto itself");
        }
        let srcrect = opt_rect_of(sx, sy, sw, sh);
        let dstrect = Rect::new(i32_of(dx, "dx"), i32_of(dy, "dy"), 0, 0);
        source
            .surface_mut()
            .blit(srcrect.as_ref(), rtself.surface_mut(), Some(&dstrect))
            .or_raise();
        NilClass::new()
    }

    fn surf_blit_scaled(source: RbSurface, sx: AnyObject, sy: AnyObject, sw: AnyObject, sh: AnyObject, dx: AnyObject, dy: AnyObject, dw: AnyObject, dh: AnyObject, mode: AnyObject) -> NilClass {
        let mut source = arg(source);
        if source.equals(&rtself) {
            raise_arg("a surface cannot be blitted onto itself");
        }
        let srcrect = opt_rect_of(sx, sy, sw, sh);
        let dstrect = opt_rect_of(dx, dy, dw, dh);
        let mode = scale_mode_of(mode);
        source
            .surface_mut()
            .blit_scaled(srcrect.as_ref(), rtself.surface_mut(), dstrect.as_ref(), mode)
            .or_raise();
        NilClass::new()
    }

    fn surf_get_pixel(x: AnyObject, y: AnyObject) -> Array {
        color_array(rtself.surface().read_pixel(i32_of(x, "x"), i32_of(y, "y")).or_raise())
    }

    fn surf_set_pixel(x: AnyObject, y: AnyObject, r: AnyObject, g: AnyObject, b: AnyObject, a: AnyObject) -> NilClass {
        let color = Color::new(u8_of(r, "r"), u8_of(g, "g"), u8_of(b, "b"), u8_of(a, "a"));
        rtself.surface_mut().write_pixel(i32_of(x, "x"), i32_of(y, "y"), color).or_raise();
        NilClass::new()
    }

    fn surf_set_color_key(r: AnyObject, g: AnyObject, b: AnyObject) -> NilClass {
        let r = arg(r);
        let surface = rtself.surface_mut();
        let key = if is_nil(&r) {
            None
        } else {
            Some(surface.map_rgb(u8_of(Ok(r), "r"), u8_of(g, "g"), u8_of(b, "b")))
        };
        surface.set_color_key(key).or_raise();
        NilClass::new()
    }

    fn surf_set_alpha_mod(alpha: AnyObject) -> NilClass {
        rtself.surface_mut().set_alpha_mod(u8_of(alpha, "alpha"));
        NilClass::new()
    }

    fn surf_alpha_mod() -> Fixnum {
        Fixnum::new(rtself.surface().alpha_mod() as i64)
    }

    fn surf_set_color_mod(r: AnyObject, g: AnyObject, b: AnyObject) -> NilClass {
        rtself.surface_mut().set_color_mod(u8_of(r, "r"), u8_of(g, "g"), u8_of(b, "b"));
        NilClass::new()
    }

    fn surf_set_blend_mode(mode: AnyObject) -> NilClass {
        rtself.surface_mut().set_blend_mode(blend_mode_of(mode)).or_raise();
        NilClass::new()
    }

    fn surf_blend_mode() -> Fixnum {
        Fixnum::new(rtself.surface().blend_mode().0 as i64)
    }

    fn surf_set_clip_rect(x: AnyObject, y: AnyObject, w: AnyObject, h: AnyObject) -> Boolean {
        let rect = opt_rect_of(x, y, w, h);
        Boolean::new(rtself.surface_mut().set_clip_rect(rect.as_ref()))
    }

    fn surf_duplicate() -> AnyObject {
        wrap(rtself.surface().duplicate().or_raise())
    }

    fn surf_scale(width: AnyObject, height: AnyObject, mode: AnyObject) -> AnyObject {
        let scaled = rtself
            .surface()
            .scale(i32_of(width, "width"), i32_of(height, "height"), scale_mode_of(mode))
            .or_raise();
        wrap(scaled)
    }

    fn surf_rotate(angle: AnyObject) -> AnyObject {
        wrap(rtself.surface_mut().rotate(f32_of(angle, "angle")).or_raise())
    }

    fn surf_flip(mode: AnyObject) -> NilClass {
        rtself.surface_mut().flip(flip_mode_of(mode)).or_raise();
        NilClass::new()
    }

    // The raw pixel bytes (RGBA32, `pitch` bytes per row) as a binary String.
    fn surf_pixels() -> AnyObject {
        match rtself.surface().pixels() {
            Some(bytes) => RString::from_bytes(bytes, &Encoding::find("BINARY").unwrap()).to_any_object(),
            None => NilClass::new().to_any_object(),
        }
    }

    fn surf_write_pixels(bytes: RString) -> NilClass {
        let bytes = arg(bytes);
        let surface = rtself.surface_mut();
        let Some(pixels) = surface.pixels_mut() else {
            raise_arg("this surface has no pixel buffer");
        };
        let source = bytes.to_bytes_unchecked();
        if source.len() != pixels.len() {
            raise_arg(&format!("expected {} bytes of pixel data, got {}", pixels.len(), source.len()));
        }
        pixels.copy_from_slice(source);
        NilClass::new()
    }
);

pub fn define(native: &mut Module) {
    native.def_self("create_surface", surf_create);
    native.def_self("load_bmp", surf_load_bmp);
    native.def_self("load_image", surf_load_image);

    let mut klass = native.define_nested_class("Surface", None);
    // Instances come only from Rust (`wrap_data`), never from `Surface.new`.
    klass.undef_alloc_func();
    klass.define(|klass| {
        klass.def("width", surf_width);
        klass.def("height", surf_height);
        klass.def("pitch", surf_pitch);
        klass.def("format_name", surf_format_name);
        klass.def("save_bmp", surf_save_bmp);
        klass.def("save_png", surf_save_png);
        klass.def("fill_rect", surf_fill_rect);
        klass.def("clear", surf_clear);
        klass.def("blit", surf_blit);
        klass.def("blit_scaled", surf_blit_scaled);
        klass.def("get_pixel", surf_get_pixel);
        klass.def("set_pixel", surf_set_pixel);
        klass.def("set_color_key", surf_set_color_key);
        klass.def("alpha_mod=", surf_set_alpha_mod);
        klass.def("alpha_mod", surf_alpha_mod);
        klass.def("set_color_mod", surf_set_color_mod);
        klass.def("blend_mode=", surf_set_blend_mode);
        klass.def("blend_mode", surf_blend_mode);
        klass.def("set_clip_rect", surf_set_clip_rect);
        klass.def("duplicate", surf_duplicate);
        klass.def("scale", surf_scale);
        klass.def("rotate", surf_rotate);
        klass.def("flip", surf_flip);
        klass.def("pixels", surf_pixels);
        klass.def("pixels=", surf_write_pixels);
    });
}
