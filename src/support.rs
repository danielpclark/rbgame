//! Shared plumbing: raising Ruby exceptions from SDL errors, reading method
//! arguments as plain Rust numbers, and the macro that declares the Ruby
//! classes wrapping SDL handles.

use rutie::{AnyException, AnyObject, Array, Boolean, Class, Fixnum, Float, Module, NilClass, Object, RString, VM};
use sdl3::video::{FPoint, FRect, Rect};

/// The name of an object's class, for error messages.
pub fn class_name(object: &AnyObject) -> String {
    object
        .class()
        .name()
        .map(|name| name.to_string())
        .unwrap_or_else(|| "an anonymous class".to_string())
}

/// `methods!` hands every parameter over as a `Result`.
pub type Arg<T> = Result<T, AnyException>;

pub fn rbgame() -> Module {
    Module::from_existing("Rbgame")
}

pub fn native() -> Module {
    rbgame().get_nested_module("Native")
}

/// `Rbgame::SDLError` for a failure reported by SDL.
pub fn raise_sdl(err: sdl3::Error) -> ! {
    VM::raise_message(rbgame().get_nested_class("SDLError"), &err.to_string())
}

/// `Rbgame::StateError` for a handle used after it was destroyed and the like.
pub fn raise_state(message: &str) -> ! {
    VM::raise_message(rbgame().get_nested_class("StateError"), message)
}

pub fn raise_type(message: &str) -> ! {
    VM::raise_message(Class::from_existing("TypeError"), message)
}

pub fn raise_arg(message: &str) -> ! {
    VM::raise_message(Class::from_existing("ArgumentError"), message)
}

fn raise_ex(exception: AnyException) -> ! {
    VM::raise_ex(exception);
    unreachable!("rb_raise returned")
}

/// Unwrap an SDL `Result`, raising `Rbgame::SDLError` on `Err`.
pub trait OrRaise<T> {
    fn or_raise(self) -> T;
}

impl<T> OrRaise<T> for sdl3::Result<T> {
    fn or_raise(self) -> T {
        match self {
            Ok(value) => value,
            Err(err) => raise_sdl(err),
        }
    }
}

/// A typed argument, or the `TypeError` Rutie prepared for it.
pub fn arg<T: Object>(value: Arg<T>) -> T {
    match value {
        Ok(value) => value,
        Err(exception) => raise_ex(exception),
    }
}

pub fn is_nil(object: &AnyObject) -> bool {
    object.try_convert_to::<NilClass>().is_ok()
}

/// A number argument as `f64`: Integer or Float, like most SDL coordinates.
pub fn f64_of(value: Arg<AnyObject>, what: &str) -> f64 {
    let object = arg(value);
    if let Ok(float) = object.try_convert_to::<Float>() {
        float.to_f64()
    } else if let Ok(int) = object.try_convert_to::<Fixnum>() {
        int.to_i64() as f64
    } else {
        raise_type(&format!("{what} must be a number, not {}", class_name(&object)))
    }
}

pub fn f32_of(value: Arg<AnyObject>, what: &str) -> f32 {
    f64_of(value, what) as f32
}

/// A number argument as `i64`. Floats are rounded, as pixel coordinates
/// usually want.
pub fn i64_of(value: Arg<AnyObject>, what: &str) -> i64 {
    let object = arg(value);
    if let Ok(int) = object.try_convert_to::<Fixnum>() {
        int.to_i64()
    } else if let Ok(float) = object.try_convert_to::<Float>() {
        float.to_f64().round() as i64
    } else {
        raise_type(&format!("{what} must be a number, not {}", class_name(&object)))
    }
}

pub fn i32_of(value: Arg<AnyObject>, what: &str) -> i32 {
    i64_of(value, what) as i32
}

pub fn u8_of(value: Arg<AnyObject>, what: &str) -> u8 {
    i64_of(value, what).clamp(0, 255) as u8
}

/// `nil` or a number.
pub fn opt_f32_of(value: Arg<AnyObject>, what: &str) -> Option<f32> {
    let object = arg(value);
    if is_nil(&object) {
        None
    } else {
        Some(f32_of(Ok(object), what))
    }
}

pub fn opt_i32_of(value: Arg<AnyObject>, what: &str) -> Option<i32> {
    let object = arg(value);
    if is_nil(&object) {
        None
    } else {
        Some(i32_of(Ok(object), what))
    }
}

pub fn str_of(value: Arg<RString>) -> String {
    arg(value).to_string()
}

pub fn opt_str_of(value: Arg<AnyObject>, what: &str) -> Option<String> {
    let object = arg(value);
    if is_nil(&object) {
        None
    } else if let Ok(string) = object.try_convert_to::<RString>() {
        Some(string.to_string())
    } else {
        raise_type(&format!("{what} must be a String or nil, not {}", class_name(&object)))
    }
}

/// Ruby truthiness: everything but `nil` and `false`.
pub fn truthy(value: Arg<AnyObject>) -> bool {
    let object = arg(value);
    if is_nil(&object) {
        return false;
    }
    match object.try_convert_to::<Boolean>() {
        Ok(boolean) => boolean.to_bool(),
        Err(_) => true,
    }
}

/// A flat Array of numbers as `f32`s.
pub fn f32s_of(value: Arg<Array>, what: &str) -> Vec<f32> {
    let array = arg(value);
    (0..array.length() as i64)
        .map(|i| f32_of(Ok(array.at(i)), what))
        .collect()
}

pub fn i32s_of(value: Arg<Array>, what: &str) -> Vec<i32> {
    let array = arg(value);
    (0..array.length() as i64)
        .map(|i| i32_of(Ok(array.at(i)), what))
        .collect()
}

/// Four numbers, or four `nil`s for "no rectangle".
pub fn opt_rect_of(x: Arg<AnyObject>, y: Arg<AnyObject>, w: Arg<AnyObject>, h: Arg<AnyObject>) -> Option<Rect> {
    let x = opt_i32_of(x, "x")?;
    Some(Rect::new(x, i32_of(y, "y"), i32_of(w, "w"), i32_of(h, "h")))
}

pub fn opt_frect_of(x: Arg<AnyObject>, y: Arg<AnyObject>, w: Arg<AnyObject>, h: Arg<AnyObject>) -> Option<FRect> {
    let x = opt_f32_of(x, "x")?;
    Some(FRect::new(x, f32_of(y, "y"), f32_of(w, "w"), f32_of(h, "h")))
}

/// Pairs of a flat `[x0, y0, x1, y1, ...]` array as points.
pub fn fpoints_of(value: Arg<Array>, what: &str) -> Vec<FPoint> {
    let floats = f32s_of(value, what);
    if !floats.len().is_multiple_of(2) {
        raise_arg(&format!("{what} must hold an even number of coordinates"));
    }
    floats.chunks(2).map(|p| FPoint::new(p[0], p[1])).collect()
}

/// Quadruples of a flat `[x, y, w, h, ...]` array as rectangles.
pub fn frects_of(value: Arg<Array>, what: &str) -> Vec<FRect> {
    let floats = f32s_of(value, what);
    if !floats.len().is_multiple_of(4) {
        raise_arg(&format!("{what} must hold a multiple of four numbers"));
    }
    floats.chunks(4).map(|r| FRect::new(r[0], r[1], r[2], r[3])).collect()
}

pub fn pair(a: i64, b: i64) -> Array {
    let mut array = Array::with_capacity(2);
    array.push(Fixnum::new(a));
    array.push(Fixnum::new(b));
    array
}

pub fn fpair(a: f64, b: f64) -> Array {
    let mut array = Array::with_capacity(2);
    array.push(Float::new(a));
    array.push(Float::new(b));
    array
}

pub fn ints_array(values: impl IntoIterator<Item = i64>) -> Array {
    let mut array = Array::new();
    for value in values {
        array.push(Fixnum::new(value));
    }
    array
}

/// Declare the Rust view of a Ruby class nested in `Rbgame::Native`.
///
/// Rutie's `class!` looks the class up by its *top-level* name; our classes
/// are nested, so this macro resolves them through the module instead.
macro_rules! native_class {
    ($rust:ident, $ruby:expr) => {
        #[repr(transparent)]
        pub struct $rust {
            value: rutie::types::Value,
        }

        impl From<rutie::types::Value> for $rust {
            fn from(value: rutie::types::Value) -> Self {
                $rust { value }
            }
        }

        impl rutie::Object for $rust {
            fn value(&self) -> rutie::types::Value {
                self.value
            }
        }

        impl rutie::VerifiedObject for $rust {
            fn is_correct_type<T: rutie::Object>(object: &T) -> bool {
                $crate::support::native().get_nested_class($ruby).case_equals(object)
            }

            fn error_message() -> &'static str {
                concat!("expected an Rbgame::Native::", $ruby)
            }
        }
    };
}
