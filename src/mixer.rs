//! `Rbgame::Native::Mixer` and `Rbgame::Native::Track`: SDL_mixer's mixer
//! and tracks, so clips overlap. A mixer is on the default device, or
//! offline (`render` hands back what it would have played) for tests and
//! recordings. Clips cross as signed 16-bit PCM with a rate and channel
//! count; the mixer converts.

use rutie::{AnyObject, Boolean, Encoding, Fixnum, Float, Module, NilClass, Object, RString};
use sdl3::audio::{AudioFormat, AudioSpec, AUDIO_DEVICE_DEFAULT_PLAYBACK};
use sdl3::properties::Properties;
use sdl3_mixer::{Audio, Mixer, StereoGains, Track, PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, PROP_PLAY_LOOPS_NUMBER};

use crate::music::ensure_init;
use crate::support::{arg, f32_of, i32_of, i64_of, native, raise_arg, OrRaise};

pub struct MixerBox {
    mixer: Mixer,
    spec: AudioSpec,
}

wrappable_struct!(MixerBox, MixerWrapper, MIXER_WRAPPER);
native_class!(RbMixer, "Mixer");

pub struct TrackBox {
    track: Track,
}

wrappable_struct!(TrackBox, TrackWrapper, TRACK_WRAPPER);
native_class!(RbTrack, "Track");

impl RbMixer {
    fn mixer(&self) -> &Mixer {
        &self.get_data(&*MIXER_WRAPPER).mixer
    }
}

impl RbTrack {
    fn track(&self) -> &Track {
        &self.get_data(&*TRACK_WRAPPER).track
    }
}

fn s16(freq: AnyObject, channels: AnyObject) -> AudioSpec {
    AudioSpec { format: AudioFormat::S16, channels: i32_of(Ok(channels), "channels"), freq: i32_of(Ok(freq), "freq") }
}

fn wrap_mixer(mixer: Mixer, spec: AudioSpec) -> AnyObject {
    native()
        .get_nested_class("Mixer")
        .wrap_data(MixerBox { mixer, spec }, &*MIXER_WRAPPER)
}

fn wrap_track(track: Track) -> AnyObject {
    native()
        .get_nested_class("Track")
        .wrap_data(TrackBox { track }, &*TRACK_WRAPPER)
}

// -1.0 (left) to 1.0 (right) as the gains of the two speakers.
fn stereo_gains(pan: f32) -> StereoGains {
    let pan = pan.clamp(-1.0, 1.0);
    StereoGains { left: (1.0 - pan).min(1.0), right: (1.0 + pan).min(1.0) }
}

methods!(
    AnyObject,
    _rtself,

    // On the default device; raises when none can be opened.
    fn mix_open_device(freq: AnyObject, channels: AnyObject) -> AnyObject {
        ensure_init();
        let spec = s16(freq.unwrap(), channels.unwrap());
        let mixer = Mixer::new_device(AUDIO_DEVICE_DEFAULT_PLAYBACK, Some(&spec)).or_raise();
        wrap_mixer(mixer, spec)
    }

    // No device: `render` pulls the mixed output.
    fn mix_offline(freq: AnyObject, channels: AnyObject) -> AnyObject {
        ensure_init();
        let spec = s16(freq.unwrap(), channels.unwrap());
        let mixer = Mixer::new(&spec).or_raise();
        wrap_mixer(mixer, spec)
    }
);

methods!(
    RbMixer,
    rtself,

    // Starts `pcm` (S16 at `rate` x `channels`) on a new track and returns it.
    // `loops`: 0 once, -1 forever; `gain` 0..1; `pan` -1..1.
    fn mix_play(pcm: RString, rate: AnyObject, channels: AnyObject, loops: AnyObject, gain: AnyObject, fade_in_ms: AnyObject, pan: AnyObject) -> AnyObject {
        let pcm = arg(pcm);
        let spec = s16(rate.unwrap(), channels.unwrap());
        let data = pcm.to_bytes_unchecked();
        if !data.len().is_multiple_of(2 * spec.channels.max(1) as usize) {
            raise_arg("PCM data must hold whole 16-bit frames");
        }
        let mixer = rtself.mixer();
        let audio = Audio::load_raw(Some(mixer), data, &spec).or_raise();
        let track = Track::new(mixer).or_raise();
        track.set_audio(Some(&audio)).or_raise();
        track.set_gain(f32_of(gain, "gain")).or_raise();
        let pan = f32_of(pan, "pan");
        if pan != 0.0 {
            track.set_stereo(Some(&stereo_gains(pan))).or_raise();
        }
        let options = Properties::new();
        options.set(PROP_PLAY_LOOPS_NUMBER, i64_of(loops, "loops")).or_raise();
        options.set(PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, i64_of(fade_in_ms, "fade in").max(0)).or_raise();
        track.play(Some(&options)).or_raise();
        wrap_track(track)
    }

    fn mix_stop_all(fade_out_ms: AnyObject) -> NilClass {
        rtself.mixer().stop_all_tracks(i64_of(fade_out_ms, "fade out").max(0)).or_raise();
        NilClass::new()
    }

    fn mix_pause_all() -> NilClass {
        rtself.mixer().pause_all_tracks().or_raise();
        NilClass::new()
    }

    fn mix_resume_all() -> NilClass {
        rtself.mixer().resume_all_tracks().or_raise();
        NilClass::new()
    }

    fn mix_set_gain(gain: AnyObject) -> NilClass {
        rtself.mixer().set_gain(f32_of(gain, "gain")).or_raise();
        NilClass::new()
    }

    fn mix_gain() -> Float {
        Float::new(rtself.mixer().gain().or_raise() as f64)
    }

    fn mix_freq() -> Fixnum {
        Fixnum::new(rtself.get_data(&*MIXER_WRAPPER).spec.freq as i64)
    }

    fn mix_channels() -> Fixnum {
        Fixnum::new(rtself.get_data(&*MIXER_WRAPPER).spec.channels as i64)
    }

    // The next `frames` of mixed S16 output; offline mixers only.
    fn mix_render(frames: AnyObject) -> RString {
        let data = rtself.get_data(&*MIXER_WRAPPER);
        let frames = i64_of(frames, "frames").max(0) as usize;
        let mut buffer = vec![0u8; frames * data.spec.channels.max(1) as usize * 2];
        if !buffer.is_empty() {
            data.mixer.generate(&mut buffer).or_raise();
        }
        RString::from_bytes(&buffer, &Encoding::find("BINARY").unwrap())
    }
);

methods!(
    RbTrack,
    rtself,

    fn track_playing() -> Boolean {
        Boolean::new(rtself.track().playing())
    }

    fn track_paused() -> Boolean {
        Boolean::new(rtself.track().paused())
    }

    fn track_stop(fade_out_ms: AnyObject) -> NilClass {
        let track = rtself.track();
        let frames = track.ms_to_frames(i64_of(fade_out_ms, "fade out").max(0)).or_raise();
        track.stop(frames).or_raise();
        NilClass::new()
    }

    fn track_pause() -> NilClass {
        rtself.track().pause().or_raise();
        NilClass::new()
    }

    fn track_resume() -> NilClass {
        rtself.track().resume().or_raise();
        NilClass::new()
    }

    fn track_set_gain(gain: AnyObject) -> NilClass {
        rtself.track().set_gain(f32_of(gain, "gain")).or_raise();
        NilClass::new()
    }

    fn track_gain() -> Float {
        Float::new(rtself.track().gain().or_raise() as f64)
    }

    fn track_set_pan(pan: AnyObject) -> NilClass {
        let pan = f32_of(pan, "pan");
        let gains = if pan == 0.0 { None } else { Some(stereo_gains(pan)) };
        rtself.track().set_stereo(gains.as_ref()).or_raise();
        NilClass::new()
    }
);

pub fn define(native: &mut Module) {
    let mut mixer = native.define_nested_class("Mixer", None);
    mixer.undef_alloc_func();
    mixer.def_self("open_device", mix_open_device);
    mixer.def_self("offline", mix_offline);
    mixer.def("play", mix_play);
    mixer.def("stop_all", mix_stop_all);
    mixer.def("pause_all", mix_pause_all);
    mixer.def("resume_all", mix_resume_all);
    mixer.def("gain=", mix_set_gain);
    mixer.def("gain", mix_gain);
    mixer.def("freq", mix_freq);
    mixer.def("channels", mix_channels);
    mixer.def("render", mix_render);

    let mut track = native.define_nested_class("Track", None);
    track.undef_alloc_func();
    track.def("playing?", track_playing);
    track.def("paused?", track_paused);
    track.def("stop", track_stop);
    track.def("pause", track_pause);
    track.def("resume", track_resume);
    track.def("gain=", track_set_gain);
    track.def("gain", track_gain);
    track.def("pan=", track_set_pan);
}
