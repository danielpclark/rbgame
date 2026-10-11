//! `Rbgame::Native::Gamepad`: a game controller through SDL's gamepad API,
//! which maps every supported device onto one layout. Buttons and axes cross
//! as SDL's indexes; `Rbgame::Gamepad` names them.
//!
//! `Rbgame::Native::VirtualGamepad` is a pretend controller SDL treats as a
//! real one, so tests and demos can press its buttons and tilt its sensors.

use rutie::{AnyObject, Array, Boolean, Fixnum, Float, NilClass, Object, RString};
use sdl3::gamepad::{Gamepad, GamepadAxis, GamepadButton};
use sdl3::events::JoystickID;
use sdl3::joystick::{attach_virtual_joystick, detach_virtual_joystick, Joystick, JoystickType, VirtualJoystickDesc, VirtualJoystickSensorDesc};
use sdl3::sensor::SensorType;

use crate::sensor::{floats, sensor_type_of};
use crate::support::{f32s_of, i32_of, i64_of, ints_array, native, opt_string, raise_arg, raise_state, str_of, truthy, u8_of, OrRaise};

pub struct GamepadBox {
    gamepad: Option<Gamepad>,
}

wrappable_struct!(GamepadBox, GamepadWrapper, GAMEPAD_WRAPPER);
native_class!(RbGamepad, "Gamepad");

pub struct VirtualBox {
    id: JoystickID,
    joystick: Option<Joystick>,
}

wrappable_struct!(VirtualBox, VirtualWrapper, VIRTUAL_WRAPPER);
native_class!(RbVirtualGamepad, "VirtualGamepad");

/// The standard buttons a virtual pad has: south through dpad_right.
const VIRTUAL_BUTTONS: u16 = 15;
const VIRTUAL_AXES: u16 = 6;

impl RbGamepad {
    fn gamepad(&mut self) -> &Gamepad {
        match &self.get_data_mut(&*GAMEPAD_WRAPPER).gamepad {
            Some(gamepad) => gamepad,
            None => raise_state("gamepad is closed"),
        }
    }
}

impl RbVirtualGamepad {
    fn joystick(&mut self) -> &Joystick {
        match &self.get_data_mut(&*VIRTUAL_WRAPPER).joystick {
            Some(joystick) => joystick,
            None => raise_state("virtual gamepad is detached"),
        }
    }
}

fn button_of(index: i32) -> GamepadButton {
    match GamepadButton::from_i32(index) {
        GamepadButton::Invalid => raise_arg("no such gamepad button"),
        button => button,
    }
}

fn axis_of(index: i32) -> GamepadAxis {
    match usize::try_from(index).ok().and_then(|i| GamepadAxis::all().nth(i)) {
        Some(axis) => axis,
        None => raise_arg("no such gamepad axis"),
    }
}

fn id_of(value: AnyObject) -> JoystickID {
    i64_of(Ok(value), "id") as JoystickID
}

methods!(
    AnyObject,
    _rtself,

    fn pad_ids() -> Array {
        ints_array(sdl3::gamepad::gamepads().into_iter().map(|id| id as i64))
    }

    fn pad_open(id: AnyObject) -> AnyObject {
        let gamepad = Gamepad::open(id_of(id.unwrap())).or_raise();
        native()
            .get_nested_class("Gamepad")
            .wrap_data(GamepadBox { gamepad: Some(gamepad) }, &*GAMEPAD_WRAPPER)
    }

    fn vpad_attach(name: RString) -> AnyObject {
        let sensor = |sensor_type| VirtualJoystickSensorDesc { sensor_type, rate: 0.0 };
        let desc = VirtualJoystickDesc {
            joystick_type: JoystickType::Gamepad,
            naxes: VIRTUAL_AXES,
            nbuttons: VIRTUAL_BUTTONS,
            sensors: vec![sensor(SensorType::Accel), sensor(SensorType::Gyro)],
            name: Some(str_of(name)),
            ..VirtualJoystickDesc::default()
        };
        let id = attach_virtual_joystick(desc).or_raise();
        let joystick = Joystick::open(id).or_raise();
        native()
            .get_nested_class("VirtualGamepad")
            .wrap_data(VirtualBox { id, joystick: Some(joystick) }, &*VIRTUAL_WRAPPER)
    }
);

methods!(
    RbGamepad,
    rtself,

    fn pad_id() -> Fixnum {
        Fixnum::new(rtself.gamepad().id() as i64)
    }

    fn pad_name() -> AnyObject {
        opt_string(rtself.gamepad().name().or_raise())
    }

    fn pad_type_name() -> AnyObject {
        opt_string(rtself.gamepad().gamepad_type().as_str().map(str::to_owned))
    }

    fn pad_player_index() -> Fixnum {
        Fixnum::new(rtself.gamepad().player_index() as i64)
    }

    fn pad_connected() -> Boolean {
        Boolean::new(rtself.gamepad().connected())
    }

    fn pad_button(index: AnyObject) -> Boolean {
        Boolean::new(rtself.gamepad().button(button_of(i32_of(index, "button"))))
    }

    fn pad_has_button(index: AnyObject) -> Boolean {
        Boolean::new(rtself.gamepad().has_button(button_of(i32_of(index, "button"))))
    }

    fn pad_axis(index: AnyObject) -> Fixnum {
        Fixnum::new(rtself.gamepad().axis(axis_of(i32_of(index, "axis"))) as i64)
    }

    fn pad_has_axis(index: AnyObject) -> Boolean {
        Boolean::new(rtself.gamepad().has_axis(axis_of(i32_of(index, "axis"))))
    }

    // Strengths 0..0xFFFF; false when this pad cannot rumble.
    fn pad_rumble(low: AnyObject, high: AnyObject, ms: AnyObject) -> Boolean {
        let (low, high) = (i64_of(low, "low") as u16, i64_of(high, "high") as u16);
        let ms = i64_of(ms, "ms") as u32;
        Boolean::new(rtself.gamepad().rumble(low, high, ms).is_ok())
    }

    fn pad_rumble_triggers(left: AnyObject, right: AnyObject, ms: AnyObject) -> Boolean {
        let (left, right) = (i64_of(left, "left") as u16, i64_of(right, "right") as u16);
        let ms = i64_of(ms, "ms") as u32;
        Boolean::new(rtself.gamepad().rumble_triggers(left, right, ms).is_ok())
    }

    fn pad_set_led(r: AnyObject, g: AnyObject, b: AnyObject) -> Boolean {
        let (r, g, b) = (u8_of(r, "r"), u8_of(g, "g"), u8_of(b, "b"));
        Boolean::new(rtself.gamepad().set_led(r, g, b).is_ok())
    }

    // Sensor types are SDL's numbers; see `Rbgame::Sensor::TYPES`.
    fn pad_has_sensor(index: AnyObject) -> Boolean {
        Boolean::new(rtself.gamepad().has_sensor(sensor_type_of(i32_of(index, "sensor"))))
    }

    fn pad_set_sensor_enabled(index: AnyObject, enabled: AnyObject) -> NilClass {
        let sensor_type = sensor_type_of(i32_of(index, "sensor"));
        rtself.gamepad().set_sensor_enabled(sensor_type, truthy(enabled)).or_raise();
        NilClass::new()
    }

    fn pad_sensor_enabled(index: AnyObject) -> Boolean {
        Boolean::new(rtself.gamepad().sensor_enabled(sensor_type_of(i32_of(index, "sensor"))))
    }

    // Readings per second, 0.0 when unknown.
    fn pad_sensor_rate(index: AnyObject) -> Float {
        Float::new(rtself.gamepad().sensor_data_rate(sensor_type_of(i32_of(index, "sensor"))) as f64)
    }

    // The latest [x, y, z] of a sensor: m/s^2 for accelerometers, rad/s for gyroscopes.
    fn pad_sensor_data(index: AnyObject) -> Array {
        let mut data = [0.0f32; 3];
        rtself.gamepad().sensor_data(sensor_type_of(i32_of(index, "sensor")), &mut data).or_raise();
        floats(data)
    }

    fn pad_close() -> NilClass {
        rtself.get_data_mut(&*GAMEPAD_WRAPPER).gamepad = None;
        NilClass::new()
    }
);

methods!(
    RbVirtualGamepad,
    rtself,

    fn vpad_id() -> Fixnum {
        Fixnum::new(rtself.get_data_mut(&*VIRTUAL_WRAPPER).id as i64)
    }

    fn vpad_set_button(index: AnyObject, down: AnyObject) -> NilClass {
        let index = i32_of(index, "button");
        if !(0..VIRTUAL_BUTTONS as i32).contains(&index) {
            raise_arg("the virtual gamepad has no such button");
        }
        rtself.joystick().set_virtual_button(index as usize, truthy(down)).or_raise();
        NilClass::new()
    }

    // `value` is SDL's -32768..32767.
    fn vpad_set_axis(index: AnyObject, value: AnyObject) -> NilClass {
        let index = i32_of(index, "axis");
        if !(0..VIRTUAL_AXES as i32).contains(&index) {
            raise_arg("the virtual gamepad has no such axis");
        }
        let value = i64_of(value, "value").clamp(i16::MIN as i64, i16::MAX as i64) as i16;
        rtself.joystick().set_virtual_axis(index as usize, value).or_raise();
        NilClass::new()
    }

    // A reading from one of the pad's sensors (accelerometer or gyroscope),
    // delivered on the next pump once the pad has that sensor enabled.
    fn vpad_send_sensor(index: AnyObject, timestamp_ns: AnyObject, values: Array) -> NilClass {
        let sensor_type = sensor_type_of(i32_of(index, "sensor"));
        let timestamp = i64_of(timestamp_ns, "timestamp_ns").max(0) as u64;
        let values = f32s_of(values, "values");
        if values.len() != 3 {
            raise_arg("a sensor reading has three values");
        }
        rtself.joystick().send_virtual_sensor_data(sensor_type, timestamp, &values).or_raise();
        NilClass::new()
    }

    fn vpad_detach() -> NilClass {
        let data = rtself.get_data_mut(&*VIRTUAL_WRAPPER);
        if data.joystick.take().is_some() {
            detach_virtual_joystick(data.id).or_raise();
        }
        NilClass::new()
    }
);

pub fn define(native: &mut rutie::Module) {
    let mut klass = native.define_nested_class("Gamepad", None);
    klass.undef_alloc_func();
    klass.def_self("ids", pad_ids);
    klass.def_self("open", pad_open);
    klass.def("id", pad_id);
    klass.def("name", pad_name);
    klass.def("type_name", pad_type_name);
    klass.def("player_index", pad_player_index);
    klass.def("connected?", pad_connected);
    klass.def("button?", pad_button);
    klass.def("has_button?", pad_has_button);
    klass.def("axis", pad_axis);
    klass.def("has_axis?", pad_has_axis);
    klass.def("rumble", pad_rumble);
    klass.def("rumble_triggers", pad_rumble_triggers);
    klass.def("set_led", pad_set_led);
    klass.def("has_sensor?", pad_has_sensor);
    klass.def("set_sensor_enabled", pad_set_sensor_enabled);
    klass.def("sensor_enabled?", pad_sensor_enabled);
    klass.def("sensor_rate", pad_sensor_rate);
    klass.def("sensor_data", pad_sensor_data);
    klass.def("close", pad_close);

    let mut virtual_klass = native.define_nested_class("VirtualGamepad", None);
    virtual_klass.undef_alloc_func();
    virtual_klass.def_self("attach", vpad_attach);
    virtual_klass.def("id", vpad_id);
    virtual_klass.def("set_button", vpad_set_button);
    virtual_klass.def("set_axis", vpad_set_axis);
    virtual_klass.def("send_sensor", vpad_send_sensor);
    virtual_klass.def("detach", vpad_detach);
}
