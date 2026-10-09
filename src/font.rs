//! `Rbgame::Native::Font`: a TrueType or OpenType font through SDL_ttf.
//! Text crosses as UTF-8 and comes back as `Rbgame::Native::Surface`s.

use std::sync::Once;

use rutie::{AnyObject, Array, Boolean, Fixnum, Float, Module, NilClass, Object, RString};
use sdl3::video::Color;
use sdl3_ttf::Font;

use crate::support::{f32_of, i32_of, i64_of, is_nil, native, opt_string, pair, raise_state, str_of, u8_of, OrRaise};

static TTF_INIT: Once = Once::new();

fn ensure_init() {
    TTF_INIT.call_once(|| {
        let _ = sdl3_ttf::init();
    });
}

pub struct FontBox {
    font: Option<Font>,
}

wrappable_struct!(FontBox, FontWrapper, FONT_WRAPPER);
native_class!(RbFont, "Font");

impl RbFont {
    fn font(&self) -> &Font {
        match &self.get_data(&*FONT_WRAPPER).font {
            Some(font) => font,
            None => raise_state("font is closed"),
        }
    }
}

methods!(
    AnyObject,
    _rtself,

    fn font_open(path: RString, points: AnyObject) -> AnyObject {
        ensure_init();
        let font = Font::open(&str_of(path), f32_of(points, "size")).or_raise();
        native()
            .get_nested_class("Font")
            .wrap_data(FontBox { font: Some(font) }, &*FONT_WRAPPER)
    }
);

methods!(
    RbFont,
    rtself,

    fn font_size() -> Float {
        Float::new(rtself.font().size() as f64)
    }

    fn font_set_size(points: AnyObject) -> NilClass {
        rtself.font().set_size(f32_of(points, "size")).or_raise();
        NilClass::new()
    }

    fn font_height() -> Fixnum {
        Fixnum::new(rtself.font().height() as i64)
    }

    fn font_ascent() -> Fixnum {
        Fixnum::new(rtself.font().ascent() as i64)
    }

    fn font_line_skip() -> Fixnum {
        Fixnum::new(rtself.font().line_skip() as i64)
    }

    fn font_family_name() -> AnyObject {
        opt_string(rtself.font().family_name())
    }

    fn font_fixed_width() -> Boolean {
        Boolean::new(rtself.font().is_fixed_width())
    }

    // SDL_ttf's style bits: 1 bold, 2 italic, 4 underline, 8 strikethrough.
    fn font_style() -> Fixnum {
        Fixnum::new(rtself.font().style() as i64)
    }

    fn font_set_style(bits: AnyObject) -> NilClass {
        rtself.font().set_style(i64_of(bits, "style") as u32);
        NilClass::new()
    }

    fn font_outline() -> Fixnum {
        Fixnum::new(rtself.font().outline() as i64)
    }

    fn font_set_outline(pixels: AnyObject) -> NilClass {
        rtself.font().set_outline(i32_of(pixels, "outline")).or_raise();
        NilClass::new()
    }

    // [width, height] of `text`, wrapped at `wrap` pixels when not nil.
    fn font_measure(text: RString, wrap: AnyObject) -> Array {
        let text = str_of(text);
        let wrap = wrap.unwrap();
        let (w, h) = if is_nil(&wrap) {
            rtself.font().string_size(&text).or_raise()
        } else {
            rtself.font().string_size_wrapped(&text, i32_of(Ok(wrap), "wrap")).or_raise()
        };
        pair(w as i64, h as i64)
    }

    // Anti-aliased RGBA; `wrap` as in `measure`.
    fn font_render(text: RString, r: AnyObject, g: AnyObject, b: AnyObject, a: AnyObject, wrap: AnyObject) -> AnyObject {
        let text = str_of(text);
        let color = Color { r: u8_of(r, "r"), g: u8_of(g, "g"), b: u8_of(b, "b"), a: u8_of(a, "a") };
        let wrap = wrap.unwrap();
        let surface = if is_nil(&wrap) {
            rtself.font().render_text_blended(&text, color).or_raise()
        } else {
            rtself.font().render_text_blended_wrapped(&text, color, i32_of(Ok(wrap), "wrap")).or_raise()
        };
        crate::surface::wrap(surface)
    }

    fn font_close() -> NilClass {
        rtself.get_data_mut(&*FONT_WRAPPER).font = None;
        NilClass::new()
    }
);

pub fn define(native: &mut Module) {
    let mut klass = native.define_nested_class("Font", None);
    klass.undef_alloc_func();
    klass.def_self("open", font_open);
    klass.def("size", font_size);
    klass.def("size=", font_set_size);
    klass.def("height", font_height);
    klass.def("ascent", font_ascent);
    klass.def("line_skip", font_line_skip);
    klass.def("family_name", font_family_name);
    klass.def("fixed_width?", font_fixed_width);
    klass.def("style", font_style);
    klass.def("style=", font_set_style);
    klass.def("outline", font_outline);
    klass.def("outline=", font_set_outline);
    klass.def("measure", font_measure);
    klass.def("render", font_render);
    klass.def("close", font_close);
}
