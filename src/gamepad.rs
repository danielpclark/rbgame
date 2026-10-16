//! `Rbgame::Native::Gamepad`: a game controller through SDL's gamepad API,
//! which maps every supported device onto one layout. Buttons, axes and
//! sensors cross as SDL's indexes; `Rbgame::Gamepad` names them.
//!
//! `Rbgame::Native::VirtualGamepad` is a pretend controller SDL treats as a
//! real one, so tests and demos can press its buttons and tilt its sensors.

use rutie::{rubyclass, rubymethods};
use sdl3::events::JoystickID;
use sdl3::gamepad::{Gamepad as SdlGamepad, GamepadAxis, GamepadButton};
use sdl3::joystick::{attach_virtual_joystick, detach_virtual_joystick, Joystick, JoystickType, VirtualJoystickDesc, VirtualJoystickSensorDesc};
use sdl3::sensor::SensorType;

use crate::sensor::sensor_type_of;
use crate::support::{arg_error, state_error, Chan, Int, NativeResult, Num, Truthy};

/// Instances come only from `Gamepad.open`.
#[rubyclass(path = "Rbgame::Native::Gamepad", allocator = false)]
pub struct Gamepad {
    gamepad: Option<SdlGamepad>,
}

/// Instances come only from `VirtualGamepad.attach`.
#[rubyclass(path = "Rbgame::Native::VirtualGamepad", allocator = false)]
pub struct VirtualGamepad {
    id: JoystickID,
    joystick: Option<Joystick>,
}

/// The standard buttons a virtual pad has: south through dpad_right.
const VIRTUAL_BUTTONS: u16 = 15;
const VIRTUAL_AXES: u16 = 6;

impl Gamepad {
    fn get(&self) -> NativeResult<&SdlGamepad> {
        match &self.gamepad {
            Some(gamepad) => Ok(gamepad),
            None => state_error("gamepad is closed"),
        }
    }
}

impl VirtualGamepad {
    fn get(&self) -> NativeResult<&Joystick> {
        match &self.joystick {
            Some(joystick) => Ok(joystick),
            None => state_error("virtual gamepad is detached"),
        }
    }
}

fn button_of(index: Int) -> NativeResult<GamepadButton> {
    match GamepadButton::from_i32(index.0 as i32) {
        GamepadButton::Invalid => arg_error("no such gamepad button"),
        button => Ok(button),
    }
}

fn axis_of(index: Int) -> NativeResult<GamepadAxis> {
    match usize::try_from(index.0).ok().and_then(|i| GamepadAxis::all().nth(i)) {
        Some(axis) => Ok(axis),
        None => arg_error("no such gamepad axis"),
    }
}

#[rubymethods]
impl Gamepad {
    pub fn ids() -> Vec<i64> {
        sdl3::gamepad::gamepads().into_iter().map(|id| id as i64).collect()
    }

    pub fn open(id: Int) -> NativeResult<Gamepad> {
        Ok(Gamepad { gamepad: Some(SdlGamepad::open(id.0 as JoystickID)?) })
    }

    pub fn id(&self) -> NativeResult<i64> {
        Ok(self.get()?.id() as i64)
    }

    pub fn name(&self) -> NativeResult<Option<String>> {
        Ok(self.get()?.name()?)
    }

    pub fn type_name(&self) -> NativeResult<Option<String>> {
        Ok(self.get()?.gamepad_type().as_str().map(str::to_owned))
    }

    pub fn player_index(&self) -> NativeResult<i64> {
        Ok(self.get()?.player_index() as i64)
    }

    #[ruby(name = "connected?")]
    pub fn connected(&self) -> NativeResult<bool> {
        Ok(self.get()?.connected())
    }

    #[ruby(name = "button?")]
    pub fn button(&self, index: Int) -> NativeResult<bool> {
        Ok(self.get()?.button(button_of(index)?))
    }

    #[ruby(name = "has_button?")]
    pub fn has_button(&self, index: Int) -> NativeResult<bool> {
        Ok(self.get()?.has_button(button_of(index)?))
    }

    pub fn axis(&self, index: Int) -> NativeResult<i64> {
        Ok(self.get()?.axis(axis_of(index)?) as i64)
    }

    #[ruby(name = "has_axis?")]
    pub fn has_axis(&self, index: Int) -> NativeResult<bool> {
        Ok(self.get()?.has_axis(axis_of(index)?))
    }

    // Strengths 0..0xFFFF; false when this pad cannot rumble.
    pub fn rumble(&self, low: Int, high: Int, ms: Int) -> NativeResult<bool> {
        Ok(self.get()?.rumble(low.0 as u16, high.0 as u16, ms.0 as u32).is_ok())
    }

    pub fn rumble_triggers(&self, left: Int, right: Int, ms: Int) -> NativeResult<bool> {
        Ok(self.get()?.rumble_triggers(left.0 as u16, right.0 as u16, ms.0 as u32).is_ok())
    }

    pub fn set_led(&self, r: Chan, g: Chan, b: Chan) -> NativeResult<bool> {
        Ok(self.get()?.set_led(r.0, g.0, b.0).is_ok())
    }

    // Sensor types are SDL's numbers; see `Rbgame::Sensor::TYPES`.
    #[ruby(name = "has_sensor?")]
    pub fn has_sensor(&self, index: Int) -> NativeResult<bool> {
        Ok(self.get()?.has_sensor(sensor_type_of(index)?))
    }

    pub fn set_sensor_enabled(&self, index: Int, enabled: Truthy) -> NativeResult<()> {
        Ok(self.get()?.set_sensor_enabled(sensor_type_of(index)?, enabled.0)?)
    }

    #[ruby(name = "sensor_enabled?")]
    pub fn sensor_enabled(&self, index: Int) -> NativeResult<bool> {
        Ok(self.get()?.sensor_enabled(sensor_type_of(index)?))
    }

    // Readings per second, 0.0 when unknown.
    pub fn sensor_rate(&self, index: Int) -> NativeResult<f64> {
        Ok(self.get()?.sensor_data_rate(sensor_type_of(index)?) as f64)
    }

    // The latest [x, y, z] of a sensor: m/s^2 for accelerometers, rad/s for gyroscopes.
    pub fn sensor_data(&self, index: Int) -> NativeResult<Vec<f32>> {
        let mut data = [0.0f32; 3];
        self.get()?.sensor_data(sensor_type_of(index)?, &mut data)?;
        Ok(data.to_vec())
    }

    pub fn close(&mut self) {
        self.gamepad = None;
    }
}

#[rubymethods]
impl VirtualGamepad {
    pub fn attach(name: &str) -> NativeResult<VirtualGamepad> {
        let sensor = |sensor_type| VirtualJoystickSensorDesc { sensor_type, rate: 0.0 };
        let desc = VirtualJoystickDesc {
            joystick_type: JoystickType::Gamepad,
            naxes: VIRTUAL_AXES,
            nbuttons: VIRTUAL_BUTTONS,
            sensors: vec![sensor(SensorType::Accel), sensor(SensorType::Gyro)],
            name: Some(name.to_owned()),
            ..VirtualJoystickDesc::default()
        };
        let id = attach_virtual_joystick(desc)?;
        let joystick = Joystick::open(id)?;
        Ok(VirtualGamepad { id, joystick: Some(joystick) })
    }

    pub fn id(&self) -> i64 {
        self.id as i64
    }

    pub fn set_button(&self, index: Int, down: Truthy) -> NativeResult<()> {
        if !(0..VIRTUAL_BUTTONS as i64).contains(&index.0) {
            return arg_error("the virtual gamepad has no such button");
        }
        Ok(self.get()?.set_virtual_button(index.0 as usize, down.0)?)
    }

    // `value` is SDL's -32768..32767.
    pub fn set_axis(&self, index: Int, value: Int) -> NativeResult<()> {
        if !(0..VIRTUAL_AXES as i64).contains(&index.0) {
            return arg_error("the virtual gamepad has no such axis");
        }
        let value = value.0.clamp(i16::MIN as i64, i16::MAX as i64) as i16;
        Ok(self.get()?.set_virtual_axis(index.0 as usize, value)?)
    }

    // A reading from one of the pad's sensors (accelerometer or gyroscope),
    // delivered on the next pump once the pad has that sensor enabled.
    pub fn send_sensor(&self, index: Int, timestamp_ns: Int, values: Vec<Num>) -> NativeResult<()> {
        if values.len() != 3 {
            return arg_error("a sensor reading has three values");
        }
        let values: Vec<f32> = values.iter().map(|value| value.0 as f32).collect();
        Ok(self.get()?.send_virtual_sensor_data(sensor_type_of(index)?, timestamp_ns.0.max(0) as u64, &values)?)
    }

    pub fn detach(&mut self) -> NativeResult<()> {
        if self.joystick.take().is_some() {
            detach_virtual_joystick(self.id)?;
        }
        Ok(())
    }
}

pub fn define() {
    Gamepad::define_ruby();
    VirtualGamepad::define_ruby();
}
