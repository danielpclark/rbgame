//! Shared plumbing: the errors the native layer returns (raised as Ruby
//! exceptions by Rutie once a method's values are dropped), and the lenient
//! number arguments SDL coordinates want.

use rutie::derive::{FromArgument, IntoException};
use rutie::{AnyException, AnyObject, Class, Float, Integer, Object, RString};
use rutie::types::ValueType;
use sdl3::video::{FPoint, FRect, Rect};

/// What a native method can fail with. Each becomes one Ruby exception
/// class; `Rbgame::SDLError` and `Rbgame::StateError` are defined in Ruby
/// (`lib/rbgame/errors.rb`) before the extension loads.
#[derive(Debug)]
pub enum NativeError {
    /// A failure reported by SDL, with its message.
    Sdl(String),
    /// A handle used after it was closed or destroyed.
    State(String),
    Arg(String),
    /// A Ruby exception as it is, from a conversion or a borrow.
    Ruby(AnyException),
}

pub type NativeResult<T> = Result<T, NativeError>;

impl From<sdl3::Error> for NativeError {
    fn from(err: sdl3::Error) -> Self {
        NativeError::Sdl(err.to_string())
    }
}

impl From<AnyException> for NativeError {
    fn from(exception: AnyException) -> Self {
        NativeError::Ruby(exception)
    }
}

/// An exception of the class at `path` (`Rbgame::SDLError`, say).
fn exception(path: &str, message: &str) -> AnyException {
    let class = Class::from_path(path).unwrap_or_else(|_| Class::from_existing("RuntimeError"));
    let instance = class.new_instance(&[RString::new_utf8(message).to_any_object()]);
    AnyException::from(instance.value())
}

impl IntoException for NativeError {
    fn into_exception(self) -> AnyException {
        match self {
            NativeError::Sdl(message) => exception("Rbgame::SDLError", &message),
            NativeError::State(message) => exception("Rbgame::StateError", &message),
            NativeError::Arg(message) => exception("ArgumentError", &message),
            NativeError::Ruby(exception) => exception,
        }
    }
}

pub fn state_error<T>(message: &str) -> NativeResult<T> {
    Err(NativeError::State(message.to_owned()))
}

pub fn arg_error<T>(message: &str) -> NativeResult<T> {
    Err(NativeError::Arg(message.to_owned()))
}

/// The name of an object's class, for error messages.
pub fn class_name(object: &AnyObject) -> String {
    object
        .class()
        .name()
        .map(|name| name.to_string())
        .unwrap_or_else(|| "an anonymous class".to_string())
}

fn type_error(object: &AnyObject, expected: &str) -> AnyException {
    exception("TypeError", &format!("expected {expected}, not {}", class_name(object)))
}

/// Integer or Float as `f64`, like most SDL coordinates.
fn number(argument: &AnyObject) -> Result<f64, AnyException> {
    match argument.ty() {
        ValueType::Float => Ok(Float::from(argument.value()).to_f64()),
        ValueType::Fixnum | ValueType::Bignum => Ok(Integer::from(argument.value()).to_f64()),
        _ => Err(type_error(argument, "a number")),
    }
}

/// Declares an argument type converted by `$convert`, held as itself.
macro_rules! argument {
    ($(#[$doc:meta])* $name:ident($inner:ty) = $convert:expr) => {
        $(#[$doc])*
        #[derive(Clone, Copy, Debug, PartialEq)]
        pub struct $name(pub $inner);

        impl FromArgument for $name {
            type Holder = $name;

            fn hold(argument: AnyObject) -> Result<$name, AnyException> {
                let convert: fn(&AnyObject) -> Result<$inner, AnyException> = $convert;
                convert(&argument).map($name)
            }

            fn borrow(holder: &$name) -> &$name {
                holder
            }
        }
    };
}

argument! {
    /// A number argument as `f64`: Integer or Float.
    Num(f64) = number
}

argument! {
    /// A number argument as `i64`; a Float is rounded, as pixel coordinates
    /// usually want.
    Int(i64) = |argument| number(argument).map(|value| value.round() as i64)
}

argument! {
    /// A colour channel: a number clamped to 0..255.
    Chan(u8) = |argument| number(argument).map(|value| value.round().clamp(0.0, 255.0) as u8)
}

argument! {
    /// `nil` or a number.
    OptNum(Option<f64>) = |argument| if argument.is_nil() { Ok(None) } else { number(argument).map(Some) }
}

argument! {
    /// `nil` or a number, rounded.
    OptInt(Option<i64>) = |argument| if argument.is_nil() { Ok(None) } else { number(argument).map(|value| Some(value.round() as i64)) }
}

argument! {
    /// Ruby truthiness: everything but `nil` and `false`.
    Truthy(bool) = |argument| Ok(!matches!(argument.ty(), ValueType::Nil | ValueType::False))
}

/// Four numbers, or `nil` for the first for "no rectangle".
pub fn rect_of(x: OptInt, y: OptInt, w: OptInt, h: OptInt) -> Option<Rect> {
    let x = x.0?;
    Some(Rect::new(x as i32, y.0.unwrap_or(0) as i32, w.0.unwrap_or(0) as i32, h.0.unwrap_or(0) as i32))
}

pub fn frect_of(x: OptNum, y: OptNum, w: OptNum, h: OptNum) -> Option<FRect> {
    let x = x.0?;
    Some(FRect::new(x as f32, y.0.unwrap_or(0.0) as f32, w.0.unwrap_or(0.0) as f32, h.0.unwrap_or(0.0) as f32))
}

/// Pairs of a flat `[x0, y0, x1, y1, ...]` array as points.
pub fn fpoints_of(values: &[Num]) -> NativeResult<Vec<FPoint>> {
    if !values.len().is_multiple_of(2) {
        return arg_error("points must hold an even number of coordinates");
    }
    Ok(values.chunks(2).map(|p| FPoint::new(p[0].0 as f32, p[1].0 as f32)).collect())
}

/// Quadruples of a flat `[x, y, w, h, ...]` array as rectangles.
pub fn frects_of(values: &[Num]) -> NativeResult<Vec<FRect>> {
    if !values.len().is_multiple_of(4) {
        return arg_error("rects must hold a multiple of four numbers");
    }
    Ok(values
        .chunks(4)
        .map(|r| FRect::new(r[0].0 as f32, r[1].0 as f32, r[2].0 as f32, r[3].0 as f32))
        .collect())
}

pub fn i32s(values: &[Int]) -> Vec<i32> {
    values.iter().map(|value| value.0 as i32).collect()
}
