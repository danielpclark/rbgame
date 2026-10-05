//! `Rbgame::Native::Camera`: a capture device through SDL's camera API.
//! Frames cross to Ruby as `Rbgame::Native::Surface`s, copied out of the
//! driver's buffer so the driver can reuse it at once.

use rutie::{AnyObject, Array, Fixnum, NilClass, Object, RString};
use sdl3::camera::{self, Camera, CameraPermissionState, CameraPosition, CameraSpec};
use sdl3::events::CameraID;

use crate::support::{i64_of, ints_array, native, opt_i32_of, opt_string, raise_state, strings, OrRaise};

pub struct CameraBox {
    camera: Option<Camera>,
}

wrappable_struct!(CameraBox, CameraWrapper, CAMERA_WRAPPER);
native_class!(RbCamera, "Camera");

impl RbCamera {
    fn camera(&mut self) -> &Camera {
        match &self.get_data_mut(&*CAMERA_WRAPPER).camera {
            Some(camera) => camera,
            None => raise_state("camera is closed"),
        }
    }
}

fn id_of(value: AnyObject) -> CameraID {
    i64_of(Ok(value), "id") as CameraID
}

// [width, height, frame rate numerator, frame rate denominator]
fn spec_array(spec: &CameraSpec) -> Array {
    ints_array([
        spec.width as i64,
        spec.height as i64,
        spec.framerate_numerator as i64,
        spec.framerate_denominator as i64,
    ])
}

fn position_name(position: CameraPosition) -> Option<String> {
    match position {
        CameraPosition::FrontFacing => Some("front".to_owned()),
        CameraPosition::BackFacing => Some("back".to_owned()),
        CameraPosition::Unknown => None,
    }
}

fn permission_name(state: CameraPermissionState) -> &'static str {
    match state {
        CameraPermissionState::Approved => "approved",
        CameraPermissionState::Denied => "denied",
        CameraPermissionState::Pending => "pending",
    }
}

methods!(
    AnyObject,
    _rtself,

    fn cam_drivers() -> Array {
        strings((0..camera::num_camera_drivers()).filter_map(|i| camera::camera_driver(i).ok().map(str::to_owned)))
    }

    fn cam_current_driver() -> AnyObject {
        opt_string(camera::current_camera_driver().map(str::to_owned))
    }

    fn cam_ids() -> Array {
        ints_array(camera::cameras().or_raise().into_iter().map(|id| id as i64))
    }

    fn cam_name_for(id: AnyObject) -> RString {
        RString::new_utf8(&camera::camera_name(id_of(id.unwrap())).or_raise())
    }

    fn cam_position_for(id: AnyObject) -> AnyObject {
        opt_string(position_name(camera::camera_position(id_of(id.unwrap()))))
    }

    fn cam_formats_for(id: AnyObject) -> Array {
        let mut array = Array::new();
        for spec in camera::camera_supported_formats(id_of(id.unwrap())).or_raise() {
            array.push(spec_array(&spec));
        }
        array
    }

    // Any of the size and frame rate may be nil: SDL then picks the
    // device's best, and converts frames to whatever was asked for.
    fn cam_open(id: AnyObject, width: AnyObject, height: AnyObject, num: AnyObject, den: AnyObject) -> AnyObject {
        let id = id_of(id.unwrap());
        let (width, height) = (opt_i32_of(width, "width"), opt_i32_of(height, "height"));
        let (num, den) = (opt_i32_of(num, "fps numerator"), opt_i32_of(den, "fps denominator"));
        let spec = if width.is_none() && height.is_none() && num.is_none() {
            None
        } else {
            Some(CameraSpec {
                width: width.unwrap_or(0),
                height: height.unwrap_or(0),
                framerate_numerator: num.unwrap_or(0),
                framerate_denominator: den.unwrap_or(1),
                ..CameraSpec::default()
            })
        };
        let camera = Camera::open(id, spec.as_ref()).or_raise();
        native()
            .get_nested_class("Camera")
            .wrap_data(CameraBox { camera: Some(camera) }, &*CAMERA_WRAPPER)
    }
);

methods!(
    RbCamera,
    rtself,

    fn cam_id() -> Fixnum {
        Fixnum::new(rtself.camera().id() as i64)
    }

    fn cam_permission() -> RString {
        RString::new_utf8(permission_name(rtself.camera().permission_state()))
    }

    // nil until the camera is approved.
    fn cam_format() -> AnyObject {
        match rtself.camera().format() {
            Ok(spec) => spec_array(&spec).to_any_object(),
            Err(_) => NilClass::new().to_any_object(),
        }
    }

    // The newest frame as a Surface of its own, or nil when none is ready.
    fn cam_frame() -> AnyObject {
        match rtself.camera().acquire_frame().or_raise() {
            Some(frame) => {
                let copy = frame.surface().duplicate().or_raise();
                drop(frame);
                crate::surface::wrap(copy)
            }
            None => NilClass::new().to_any_object(),
        }
    }

    fn cam_close() -> NilClass {
        rtself.get_data_mut(&*CAMERA_WRAPPER).camera = None;
        NilClass::new()
    }
);

pub fn define(native: &mut rutie::Module) {
    let mut klass = native.define_nested_class("Camera", None);
    klass.undef_alloc_func();
    klass.def_self("drivers", cam_drivers);
    klass.def_self("current_driver", cam_current_driver);
    klass.def_self("ids", cam_ids);
    klass.def_self("name_for", cam_name_for);
    klass.def_self("position_for", cam_position_for);
    klass.def_self("formats_for", cam_formats_for);
    klass.def_self("open", cam_open);
    klass.def("id", cam_id);
    klass.def("permission", cam_permission);
    klass.def("format", cam_format);
    klass.def("frame", cam_frame);
    klass.def("close", cam_close);
}
