//! The event queue. Events cross into Ruby as plain Hashes with Symbol keys;
//! `Rbgame::Event` turns them into immutable `Data` objects.

use std::time::Duration;

use rutie::{AnyObject, Boolean, Fixnum, Float, Hash, Module, NilClass, Object, RString, Symbol, Thread};
use sdl3::events::{queue, Event, EventType};

use crate::support::{i64_of, is_nil, arg, OrRaise};

fn put<V: Object>(hash: &mut Hash, key: &str, value: V) {
    hash.store(Symbol::new(key), value);
}

fn put_type(hash: &mut Hash, name: &str) {
    put(hash, "type", Symbol::new(name));
}

fn window_event_name(event_type: EventType) -> &'static str {
    match event_type {
        EventType::WINDOW_SHOWN => "shown",
        EventType::WINDOW_HIDDEN => "hidden",
        EventType::WINDOW_EXPOSED => "exposed",
        EventType::WINDOW_MOVED => "moved",
        EventType::WINDOW_RESIZED => "resized",
        EventType::WINDOW_PIXEL_SIZE_CHANGED => "pixel_size_changed",
        EventType::WINDOW_MINIMIZED => "minimized",
        EventType::WINDOW_MAXIMIZED => "maximized",
        EventType::WINDOW_RESTORED => "restored",
        EventType::WINDOW_MOUSE_ENTER => "mouse_enter",
        EventType::WINDOW_MOUSE_LEAVE => "mouse_leave",
        EventType::WINDOW_FOCUS_GAINED => "focus_gained",
        EventType::WINDOW_FOCUS_LOST => "focus_lost",
        EventType::WINDOW_CLOSE_REQUESTED => "close_requested",
        EventType::WINDOW_DISPLAY_CHANGED => "display_changed",
        EventType::WINDOW_DISPLAY_SCALE_CHANGED => "display_scale_changed",
        EventType::WINDOW_OCCLUDED => "occluded",
        EventType::WINDOW_ENTER_FULLSCREEN => "enter_fullscreen",
        EventType::WINDOW_LEAVE_FULLSCREEN => "leave_fullscreen",
        EventType::WINDOW_DESTROYED => "destroyed",
        _ => "other",
    }
}

/// The Ruby-side shape of an SDL event.
pub fn event_to_hash(event: Event) -> Hash {
    let mut hash = Hash::new();
    put(&mut hash, "timestamp_ns", Fixnum::new(event.timestamp().as_nanos() as i64));
    if let Some(window_id) = event.window_id() {
        put(&mut hash, "window_id", Fixnum::new(window_id as i64));
    }

    match event {
        Event::Quit(_) => put_type(&mut hash, "quit"),
        Event::Key(key) => {
            put_type(&mut hash, if key.down { "key_down" } else { "key_up" });
            put(&mut hash, "key", Fixnum::new(key.key.0 as i64));
            put(&mut hash, "scancode", Fixnum::new(key.scancode.0 as i64));
            put(&mut hash, "name", RString::new_utf8(&key.key.name()));
            put(&mut hash, "modifiers", Fixnum::new(key.modifiers.0 as i64));
            put(&mut hash, "repeat", Boolean::new(key.repeat));
        }
        Event::TextInput(text) => {
            put_type(&mut hash, "text_input");
            put(&mut hash, "text", RString::new_utf8(&text.text));
        }
        Event::TextEditing(edit) => {
            put_type(&mut hash, "text_editing");
            put(&mut hash, "text", RString::new_utf8(&edit.text));
            put(&mut hash, "start", Fixnum::new(edit.start as i64));
            put(&mut hash, "length", Fixnum::new(edit.length as i64));
        }
        Event::MouseMotion(motion) => {
            put_type(&mut hash, "mouse_motion");
            put(&mut hash, "x", Float::new(motion.x as f64));
            put(&mut hash, "y", Float::new(motion.y as f64));
            put(&mut hash, "xrel", Float::new(motion.xrel as f64));
            put(&mut hash, "yrel", Float::new(motion.yrel as f64));
            put(&mut hash, "buttons", Fixnum::new(motion.state.0 as i64));
        }
        Event::MouseButton(button) => {
            put_type(&mut hash, if button.down { "mouse_down" } else { "mouse_up" });
            put(&mut hash, "x", Float::new(button.x as f64));
            put(&mut hash, "y", Float::new(button.y as f64));
            put(&mut hash, "button", Fixnum::new(button.button as i64));
            put(&mut hash, "clicks", Fixnum::new(button.clicks as i64));
        }
        Event::MouseWheel(wheel) => {
            put_type(&mut hash, "mouse_wheel");
            put(&mut hash, "x", Float::new(wheel.x as f64));
            put(&mut hash, "y", Float::new(wheel.y as f64));
            put(&mut hash, "mouse_x", Float::new(wheel.mouse_x as f64));
            put(&mut hash, "mouse_y", Float::new(wheel.mouse_y as f64));
        }
        Event::Window(window) => {
            put_type(&mut hash, "window");
            put(&mut hash, "event", Symbol::new(window_event_name(window.event_type)));
            put(&mut hash, "data1", Fixnum::new(window.data1 as i64));
            put(&mut hash, "data2", Fixnum::new(window.data2 as i64));
        }
        Event::Drop(drop) => {
            put_type(&mut hash, "drop");
            put(&mut hash, "x", Float::new(drop.x as f64));
            put(&mut hash, "y", Float::new(drop.y as f64));
            match drop.data {
                Some(data) => put(&mut hash, "data", RString::new_utf8(&data)),
                None => put(&mut hash, "data", NilClass::new()),
            }
        }
        Event::User(user) => {
            put_type(&mut hash, "user");
            put(&mut hash, "code", Fixnum::new(user.code as i64));
        }
        Event::GamepadDevice(device) if device.event_type == EventType::GAMEPAD_ADDED => {
            put_type(&mut hash, "gamepad_added");
            put(&mut hash, "which", Fixnum::new(device.which as i64));
        }
        Event::GamepadDevice(device) if device.event_type == EventType::GAMEPAD_REMOVED => {
            put_type(&mut hash, "gamepad_removed");
            put(&mut hash, "which", Fixnum::new(device.which as i64));
        }
        Event::GamepadButton(button) => {
            put_type(&mut hash, if button.down { "gamepad_button_down" } else { "gamepad_button_up" });
            put(&mut hash, "which", Fixnum::new(button.which as i64));
            put(&mut hash, "button", Fixnum::new(button.button as i64));
        }
        Event::GamepadAxis(axis) => {
            put_type(&mut hash, "gamepad_axis_motion");
            put(&mut hash, "which", Fixnum::new(axis.which as i64));
            put(&mut hash, "axis", Fixnum::new(axis.axis as i64));
            put(&mut hash, "raw_value", Fixnum::new(axis.value as i64));
        }
        other => {
            put_type(&mut hash, "other");
            put(&mut hash, "raw_type", Fixnum::new(other.event_type().0 as i64));
            put(&mut hash, "description", RString::new_utf8(&other.description()));
        }
    }

    hash
}

fn hash_or_nil(event: Option<Event>) -> AnyObject {
    match event {
        Some(event) => event_to_hash(event).to_any_object(),
        None => NilClass::new().to_any_object(),
    }
}

methods!(
    AnyObject,
    _rtself,

    fn ev_poll() -> AnyObject {
        hash_or_nil(queue::poll())
    }

    // Blocks without the GVL. `timeout_ms` nil waits forever.
    fn ev_wait(timeout_ms: AnyObject) -> AnyObject {
        let timeout = {
            let object = arg(timeout_ms);
            if is_nil(&object) {
                None
            } else {
                Some(Duration::from_millis(i64_of(Ok(object), "timeout_ms").max(0) as u64))
            }
        };
        let event = Thread::call_without_gvl(move || queue::wait_timeout(timeout), Some(|| {})).or_raise();
        hash_or_nil(event)
    }

    fn ev_pump() -> NilClass {
        queue::pump();
        NilClass::new()
    }

    fn ev_push_quit() -> NilClass {
        queue::send_quit();
        NilClass::new()
    }

    fn ev_push_user(code: AnyObject) -> Boolean {
        let code = i64_of(code, "code") as i32;
        let event = Event::User(sdl3::events::UserEvent {
            event_type: EventType::USER,
            timestamp: Duration::ZERO,
            window_id: 0,
            code,
            data1: None,
            data2: None,
        });
        Boolean::new(queue::push(event).or_raise())
    }

    fn ev_flush() -> NilClass {
        queue::flush_events(EventType::FIRST, EventType::LAST);
        NilClass::new()
    }

    // SDL ends each poll cycle with a sentinel event; a wait that returns an
    // event leaves it queued, and the next poll then stops at it before
    // anything pushed since. Dropping it makes the next poll start a cycle.
    fn ev_restart_poll_cycle() -> NilClass {
        queue::flush_event(EventType::POLL_SENTINEL);
        NilClass::new()
    }

    fn ev_queued_count() -> Fixnum {
        Fixnum::new(queue::queued_event_count() as i64)
    }
);

pub fn define(module: &mut Module) {
    module.def_self("poll_event", ev_poll);
    module.def_self("wait_event", ev_wait);
    module.def_self("pump_events", ev_pump);
    module.def_self("push_quit", ev_push_quit);
    module.def_self("push_user_event", ev_push_user);
    module.def_self("flush_events", ev_flush);
    module.def_self("restart_poll_cycle", ev_restart_poll_cycle);
    module.def_self("queued_event_count", ev_queued_count);
}
