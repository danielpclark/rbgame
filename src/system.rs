//! Subsystem init/quit, hints, driver queries, timing. `Rbgame::Native.*`.

use rutie::rubymodule;

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use std::time::Duration;

    use sdl3::init::InitFlags;
    use sdl3::{hints, init, timer, video};

    use crate::support::{Int, NativeResult};

    pub fn init(flags: Int) -> NativeResult<()> {
        Ok(init::init(InitFlags(flags.0 as u32))?)
    }

    pub fn quit_subsystem(flags: Int) {
        init::quit_subsystem(InitFlags(flags.0 as u32));
    }

    pub fn quit() {
        init::quit();
    }

    pub fn was_init(flags: Int) -> i64 {
        init::was_init(InitFlags(flags.0 as u32)).0 as i64
    }

    pub fn set_hint(name: &str, value: &str) -> NativeResult<bool> {
        Ok(hints::set(name, value)?)
    }

    pub fn hint(name: &str) -> Option<String> {
        hints::get(name)
    }

    pub fn reset_hint(name: &str) -> bool {
        hints::reset(name)
    }

    pub fn video_drivers() -> Vec<String> {
        (0..video::num_video_drivers())
            .filter_map(|i| video::video_driver(i).ok().map(str::to_owned))
            .collect()
    }

    pub fn current_video_driver() -> Option<String> {
        video::current_video_driver().ok().map(str::to_owned)
    }

    pub fn render_drivers() -> Vec<String> {
        (0..sdl3::render::num_render_drivers())
            .filter_map(|i| sdl3::render::render_driver(i).ok().map(str::to_owned))
            .collect()
    }

    pub fn sdl_version() -> String {
        sdl3::version().to_string()
    }

    pub fn platform() -> String {
        init::platform().to_owned()
    }

    pub fn ticks_ms() -> i64 {
        timer::ticks_ms() as i64
    }

    pub fn ticks_ns() -> i64 {
        timer::ticks_ns() as i64
    }

    pub fn performance_counter() -> i64 {
        timer::performance_counter() as i64
    }

    pub fn performance_frequency() -> i64 {
        timer::performance_frequency() as i64
    }

    // Sleeps without holding the GVL, so other Ruby threads keep running.
    #[ruby(without_gvl)]
    pub fn delay_ns(nanoseconds: i64) {
        timer::delay(Duration::from_nanos(nanoseconds.max(0) as u64));
    }

    #[ruby(without_gvl)]
    pub fn delay_precise_ns(nanoseconds: i64) {
        timer::delay_precise(Duration::from_nanos(nanoseconds.max(0) as u64));
    }

    pub fn set_app_metadata(name: &str, version: &str, identifier: &str) {
        init::set_app_metadata(Some(name), Some(version), Some(identifier));
    }
}

pub fn define() {
    functions::define_ruby();
}
