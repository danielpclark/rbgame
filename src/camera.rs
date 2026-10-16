//! `Rbgame::Native::Camera`: a capture device through SDL's camera API.
//! Frames cross to Ruby as `Rbgame::Native::Surface`s, copied out of the
//! driver's buffer so the driver can reuse it at once.

use rutie::{rubyclass, rubymethods};
use sdl3::camera::{self, Camera as SdlCamera, CameraPermissionState, CameraPosition, CameraSpec};
use sdl3::events::CameraID;

use crate::support::{state_error, Int, NativeResult, OptInt};
use crate::surface::Surface;

/// Instances come only from `Camera.open`.
#[rubyclass(path = "Rbgame::Native::Camera", allocator = false)]
pub struct Camera {
    camera: Option<SdlCamera>,
}

impl Camera {
    fn get(&self) -> NativeResult<&SdlCamera> {
        match &self.camera {
            Some(camera) => Ok(camera),
            None => state_error("camera is closed"),
        }
    }
}

// [width, height, frame rate numerator, frame rate denominator]
fn spec_tuple(spec: &CameraSpec) -> (i64, i64, i64, i64) {
    (spec.width as i64, spec.height as i64, spec.framerate_numerator as i64, spec.framerate_denominator as i64)
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

#[rubymethods]
impl Camera {
    pub fn drivers() -> Vec<String> {
        (0..camera::num_camera_drivers())
            .filter_map(|i| camera::camera_driver(i).ok().map(str::to_owned))
            .collect()
    }

    pub fn current_driver() -> Option<String> {
        camera::current_camera_driver().map(str::to_owned)
    }

    pub fn ids() -> NativeResult<Vec<i64>> {
        Ok(camera::cameras()?.into_iter().map(|id| id as i64).collect())
    }

    pub fn name_for(id: Int) -> NativeResult<String> {
        Ok(camera::camera_name(id.0 as CameraID)?)
    }

    pub fn position_for(id: Int) -> Option<String> {
        position_name(camera::camera_position(id.0 as CameraID))
    }

    pub fn formats_for(id: Int) -> NativeResult<Vec<(i64, i64, i64, i64)>> {
        Ok(camera::camera_supported_formats(id.0 as CameraID)?.iter().map(spec_tuple).collect())
    }

    // Any of the size and frame rate may be nil: SDL then picks the
    // device's best, and converts frames to whatever was asked for.
    pub fn open(id: Int, width: OptInt, height: OptInt, num: OptInt, den: OptInt) -> NativeResult<Camera> {
        let spec = if width.0.is_none() && height.0.is_none() && num.0.is_none() {
            None
        } else {
            Some(CameraSpec {
                width: width.0.unwrap_or(0) as i32,
                height: height.0.unwrap_or(0) as i32,
                framerate_numerator: num.0.unwrap_or(0) as i32,
                framerate_denominator: den.0.unwrap_or(1) as i32,
                ..CameraSpec::default()
            })
        };
        Ok(Camera { camera: Some(SdlCamera::open(id.0 as CameraID, spec.as_ref())?) })
    }

    pub fn id(&self) -> NativeResult<i64> {
        Ok(self.get()?.id() as i64)
    }

    pub fn permission(&self) -> NativeResult<String> {
        Ok(permission_name(self.get()?.permission_state()).to_owned())
    }

    // nil until the camera is approved.
    pub fn format(&self) -> NativeResult<Option<(i64, i64, i64, i64)>> {
        Ok(self.get()?.format().ok().map(|spec| spec_tuple(&spec)))
    }

    // The newest frame as a Surface of its own, or nil when none is ready.
    pub fn frame(&self) -> NativeResult<Option<Surface>> {
        match self.get()?.acquire_frame()? {
            Some(frame) => {
                let copy = frame.surface().duplicate()?;
                drop(frame);
                Ok(Some(Surface::from(copy)))
            }
            None => Ok(None),
        }
    }

    pub fn close(&mut self) {
        self.camera = None;
    }
}

pub fn define() {
    Camera::define_ruby();
}
