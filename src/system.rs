//! Subsystem init/quit, hints, driver queries, timing. `Rbgame::Native.*`.

use std::time::Duration;

use rutie::{AnyObject, Array, Boolean, Fixnum, Module, NilClass, Object, RString, Thread};
use sdl3::init::InitFlags;
use sdl3::{hints, init, timer, video};

use crate::support::{i64_of, str_of, OrRaise};

fn strings(values: impl IntoIterator<Item = String>) -> Array {
    let mut array = Array::new();
    for value in values {
        array.push(RString::new_utf8(&value));
    }
    array
}

fn opt_string(value: Option<String>) -> AnyObject {
    match value {
        Some(value) => RString::new_utf8(&value).to_any_object(),
        None => NilClass::new().to_any_object(),
    }
}

methods!(
    AnyObject,
    _rtself,

    fn sys_init(flags: AnyObject) -> NilClass {
        init::init(InitFlags(i64_of(flags, "flags") as u32)).or_raise();
        NilClass::new()
    }

    fn sys_quit_subsystem(flags: AnyObject) -> NilClass {
        init::quit_subsystem(InitFlags(i64_of(flags, "flags") as u32));
        NilClass::new()
    }

    fn sys_quit() -> NilClass {
        init::quit();
        NilClass::new()
    }

    fn sys_was_init(flags: AnyObject) -> Fixnum {
        Fixnum::new(init::was_init(InitFlags(i64_of(flags, "flags") as u32)).0 as i64)
    }

    fn sys_set_hint(name: RString, value: RString) -> Boolean {
        Boolean::new(hints::set(&str_of(name), &str_of(value)).or_raise())
    }

    fn sys_get_hint(name: RString) -> AnyObject {
        opt_string(hints::get(&str_of(name)))
    }

    fn sys_reset_hint(name: RString) -> Boolean {
        Boolean::new(hints::reset(&str_of(name)))
    }

    fn sys_video_drivers() -> Array {
        strings((0..video::num_video_drivers()).filter_map(|i| video::video_driver(i).ok().map(str::to_owned)))
    }

    fn sys_current_video_driver() -> AnyObject {
        opt_string(video::current_video_driver().ok().map(str::to_owned))
    }

    fn sys_render_drivers() -> Array {
        strings(
            (0..sdl3::render::num_render_drivers())
                .filter_map(|i| sdl3::render::render_driver(i).ok().map(str::to_owned)),
        )
    }

    fn sys_version() -> RString {
        RString::new_utf8(&sdl3::version().to_string())
    }

    fn sys_platform() -> RString {
        RString::new_utf8(init::platform())
    }

    fn sys_ticks_ms() -> Fixnum {
        Fixnum::new(timer::ticks_ms() as i64)
    }

    fn sys_ticks_ns() -> Fixnum {
        Fixnum::new(timer::ticks_ns() as i64)
    }

    fn sys_performance_counter() -> Fixnum {
        Fixnum::new(timer::performance_counter() as i64)
    }

    fn sys_performance_frequency() -> Fixnum {
        Fixnum::new(timer::performance_frequency() as i64)
    }

    // Sleeps without holding the GVL, so other Ruby threads keep running.
    fn sys_delay_ns(nanoseconds: AnyObject) -> NilClass {
        let nanoseconds = i64_of(nanoseconds, "nanoseconds").max(0) as u64;
        Thread::call_without_gvl(
            move || timer::delay(Duration::from_nanos(nanoseconds)),
            Some(|| {}),
        );
        NilClass::new()
    }

    fn sys_delay_precise_ns(nanoseconds: AnyObject) -> NilClass {
        let nanoseconds = i64_of(nanoseconds, "nanoseconds").max(0) as u64;
        Thread::call_without_gvl(
            move || timer::delay_precise(Duration::from_nanos(nanoseconds)),
            Some(|| {}),
        );
        NilClass::new()
    }

    fn sys_set_app_metadata(name: RString, version: RString, identifier: RString) -> NilClass {
        init::set_app_metadata(Some(&str_of(name)), Some(&str_of(version)), Some(&str_of(identifier)));
        NilClass::new()
    }
);

pub fn define(module: &mut Module) {
    module.def_self("init", sys_init);
    module.def_self("quit_subsystem", sys_quit_subsystem);
    module.def_self("quit", sys_quit);
    module.def_self("was_init", sys_was_init);
    module.def_self("set_hint", sys_set_hint);
    module.def_self("hint", sys_get_hint);
    module.def_self("reset_hint", sys_reset_hint);
    module.def_self("video_drivers", sys_video_drivers);
    module.def_self("current_video_driver", sys_current_video_driver);
    module.def_self("render_drivers", sys_render_drivers);
    module.def_self("sdl_version", sys_version);
    module.def_self("platform", sys_platform);
    module.def_self("ticks_ms", sys_ticks_ms);
    module.def_self("ticks_ns", sys_ticks_ns);
    module.def_self("performance_counter", sys_performance_counter);
    module.def_self("performance_frequency", sys_performance_frequency);
    module.def_self("delay_ns", sys_delay_ns);
    module.def_self("delay_precise_ns", sys_delay_precise_ns);
    module.def_self("set_app_metadata", sys_set_app_metadata);
}
