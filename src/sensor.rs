//! System facts a game asks about: `Rbgame::Native::Sensor` (the platform's
//! accelerometers and gyroscopes through SDL's sensor API; on Linux the
//! dummy driver lists none), the power supply (`power_info`) and the user's
//! preferred locales. Each crosses as primitives; `Rbgame::Sensor`,
//! `Rbgame::Power` and `Rbgame::Locale` give them their shape.

use rutie::{AnyObject, Array, Fixnum, Float, Module, NilClass, Object, RString};
use sdl3::events::SensorID;
use sdl3::power::PowerState;
use sdl3::sensor::{Sensor, SensorType};

use crate::support::{i32_of, i64_of, ints_array, native, opt_string, raise_state, OrRaise};

pub struct SensorBox {
    sensor: Option<Sensor>,
}

wrappable_struct!(SensorBox, SensorWrapper, SENSOR_WRAPPER);
native_class!(RbSensor, "Sensor");

impl RbSensor {
    fn sensor(&mut self) -> &Sensor {
        match &self.get_data_mut(&*SENSOR_WRAPPER).sensor {
            Some(sensor) => sensor,
            None => raise_state("sensor is closed"),
        }
    }
}

/// A Ruby Array of Floats.
pub fn floats(values: impl IntoIterator<Item = f32>) -> Array {
    let mut array = Array::new();
    for value in values {
        array.push(Float::new(value as f64));
    }
    array
}

/// SDL's number for a sensor type (0 unknown, 1 accelerometer, 2 gyroscope,
/// then the left and right ones of a split pad).
pub fn sensor_type_of(index: i32) -> SensorType {
    match SensorType::from_i32(index) {
        SensorType::Invalid => crate::support::raise_arg("no such sensor type"),
        sensor_type => sensor_type,
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

fn sensor_id_of(value: AnyObject) -> SensorID {
    i64_of(Ok(value), "id") as SensorID
}

methods!(
    AnyObject,
    _rtself,

    // [state, seconds_left or nil, percent or nil]
    fn power_info() -> Array {
        let info = sdl3::power::power_info();
        let mut array = Array::with_capacity(3);
        array.push(RString::new_utf8(power_state_name(info.state)));
        match info.time_left {
            Some(left) => array.push(Fixnum::new(left.as_secs() as i64)),
            None => array.push(NilClass::new()),
        };
        match info.percent {
            Some(percent) => array.push(Fixnum::new(percent as i64)),
            None => array.push(NilClass::new()),
        };
        array
    }

    // [[language, country or nil], ...] in the user's order of preference.
    fn preferred_locales() -> Array {
        let mut array = Array::new();
        for locale in sdl3::locale::preferred_locales().unwrap_or_default() {
            let mut pair = Array::with_capacity(2);
            pair.push(RString::new_utf8(&locale.language));
            pair.push(opt_string(locale.country));
            array.push(pair);
        }
        array
    }

    fn sensor_ids() -> Array {
        ints_array(sdl3::sensor::sensors().into_iter().map(|id| id as i64))
    }

    fn sensor_name_for(id: AnyObject) -> AnyObject {
        opt_string(sdl3::sensor::sensor_name_for_id(sensor_id_of(id.unwrap())).or_raise())
    }

    fn sensor_type_for(id: AnyObject) -> Fixnum {
        Fixnum::new(sdl3::sensor::sensor_type_for_id(sensor_id_of(id.unwrap())).or_raise() as i64)
    }

    fn sensor_open(id: AnyObject) -> AnyObject {
        let sensor = Sensor::open(sensor_id_of(id.unwrap())).or_raise();
        native()
            .get_nested_class("Sensor")
            .wrap_data(SensorBox { sensor: Some(sensor) }, &*SENSOR_WRAPPER)
    }
);

methods!(
    RbSensor,
    rtself,

    fn sensor_id() -> Fixnum {
        Fixnum::new(rtself.sensor().id() as i64)
    }

    fn sensor_name() -> AnyObject {
        opt_string(rtself.sensor().name().or_raise())
    }

    fn sensor_type_index() -> Fixnum {
        Fixnum::new(rtself.sensor().sensor_type() as i64)
    }

    // The latest `count` values (up to SDL's 16), as of the last pump.
    fn sensor_data(count: AnyObject) -> Array {
        let count = i32_of(count, "count").clamp(1, 16) as usize;
        let mut data = vec![0.0f32; count];
        rtself.sensor().data(&mut data).or_raise();
        floats(data)
    }

    fn sensor_close() -> NilClass {
        rtself.get_data_mut(&*SENSOR_WRAPPER).sensor = None;
        NilClass::new()
    }
);

pub fn define(native: &mut Module) {
    native.def_self("power_info", power_info);
    native.def_self("preferred_locales", preferred_locales);

    let mut klass = native.define_nested_class("Sensor", None);
    klass.undef_alloc_func();
    klass.def_self("ids", sensor_ids);
    klass.def_self("name_for", sensor_name_for);
    klass.def_self("type_for", sensor_type_for);
    klass.def_self("open", sensor_open);
    klass.def("id", sensor_id);
    klass.def("name", sensor_name);
    klass.def("type_index", sensor_type_index);
    klass.def("data", sensor_data);
    klass.def("close", sensor_close);
}
