//! System facts a game asks about: `Rbgame::Native::Sensor` (the platform's
//! accelerometers and gyroscopes through SDL's sensor API; on Linux the
//! dummy driver lists none), the power supply (`power_info`) and the user's
//! preferred locales. Each crosses as primitives; `Rbgame::Sensor`,
//! `Rbgame::Power` and `Rbgame::Locale` give them their shape.

use rutie::{rubyclass, rubymethods, rubymodule};
use sdl3::events::SensorID;
use sdl3::power::PowerState;
use sdl3::sensor::{Sensor as SdlSensor, SensorType};

use crate::support::{arg_error, state_error, Int, NativeResult};

/// Instances come only from `Sensor.open`.
#[rubyclass(path = "Rbgame::Native::Sensor", allocator = false)]
pub struct Sensor {
    sensor: Option<SdlSensor>,
}

impl Sensor {
    fn get(&self) -> NativeResult<&SdlSensor> {
        match &self.sensor {
            Some(sensor) => Ok(sensor),
            None => state_error("sensor is closed"),
        }
    }
}

/// SDL's number for a sensor type (0 unknown, 1 accelerometer, 2 gyroscope,
/// then the left and right ones of a split pad).
pub fn sensor_type_of(index: Int) -> NativeResult<SensorType> {
    match SensorType::from_i32(index.0 as i32) {
        SensorType::Invalid => arg_error("no such sensor type"),
        sensor_type => Ok(sensor_type),
    }
}

fn power_state_name(state: PowerState) -> &'static str {
    match state {
        PowerState::Error => "error",
        PowerState::Unknown => "unknown",
        PowerState::OnBattery => "on_battery",
        PowerState::NoBattery => "no_battery",
        PowerState::Charging => "charging",
        PowerState::Charged => "charged",
    }
}

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use super::power_state_name;

    // [state, seconds_left or nil, percent or nil]
    pub fn power_info() -> (String, Option<i64>, Option<i64>) {
        let info = sdl3::power::power_info();
        (
            power_state_name(info.state).to_owned(),
            info.time_left.map(|left| left.as_secs() as i64),
            info.percent.map(|percent| percent as i64),
        )
    }

    // [[language, country or nil], ...] in the user's order of preference.
    pub fn preferred_locales() -> Vec<(String, Option<String>)> {
        sdl3::locale::preferred_locales()
            .unwrap_or_default()
            .into_iter()
            .map(|locale| (locale.language, locale.country))
            .collect()
    }
}

#[rubymethods]
impl Sensor {
    pub fn ids() -> Vec<i64> {
        sdl3::sensor::sensors().into_iter().map(|id| id as i64).collect()
    }

    pub fn name_for(id: Int) -> NativeResult<Option<String>> {
        Ok(sdl3::sensor::sensor_name_for_id(id.0 as SensorID)?)
    }

    pub fn type_for(id: Int) -> NativeResult<i64> {
        Ok(sdl3::sensor::sensor_type_for_id(id.0 as SensorID)? as i64)
    }

    pub fn open(id: Int) -> NativeResult<Sensor> {
        Ok(Sensor { sensor: Some(SdlSensor::open(id.0 as SensorID)?) })
    }

    pub fn id(&self) -> NativeResult<i64> {
        Ok(self.get()?.id() as i64)
    }

    pub fn name(&self) -> NativeResult<Option<String>> {
        Ok(self.get()?.name()?)
    }

    pub fn type_index(&self) -> NativeResult<i64> {
        Ok(self.get()?.sensor_type() as i64)
    }

    // The latest `count` values (up to SDL's 16), as of the last pump.
    pub fn data(&self, count: Int) -> NativeResult<Vec<f32>> {
        let mut data = vec![0.0f32; count.0.clamp(1, 16) as usize];
        self.get()?.data(&mut data)?;
        Ok(data)
    }

    pub fn close(&mut self) {
        self.sensor = None;
    }
}

pub fn define() {
    functions::define_ruby();
    Sensor::define_ruby();
}
