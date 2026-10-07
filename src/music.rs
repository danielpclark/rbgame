//! `Rbgame::Native::Music`: streamed playback through SDL_mixer, one mixer
//! on the default device with one track. Files are decoded as they play.
//! `Rbgame::Native.decode_audio` reads a whole file into PCM instead, for
//! `Rbgame::Sound`.

use std::sync::Once;

use rutie::{AnyObject, Array, Boolean, Encoding, Fixnum, Float, Module, NilClass, Object, RString};
use sdl3::audio::{AudioFormat, AudioSpec, AUDIO_DEVICE_DEFAULT_PLAYBACK};
use sdl3::properties::Properties;
use sdl3_mixer::{Audio, AudioDecoder, Mixer, Track, PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, PROP_PLAY_LOOPS_NUMBER};

use crate::support::{f32_of, i64_of, native, str_of, OrRaise};

static MIXER_INIT: Once = Once::new();

fn ensure_init() {
    MIXER_INIT.call_once(|| {
        let _ = sdl3_mixer::init();
    });
}

pub struct MusicBox {
    mixer: Mixer,
    track: Track,
}

wrappable_struct!(MusicBox, MusicWrapper, MUSIC_WRAPPER);
native_class!(RbMusic, "Music");

impl RbMusic {
    fn track(&self) -> &Track {
        &self.get_data(&*MUSIC_WRAPPER).track
    }
}

methods!(
    AnyObject,
    _rtself,

    // Raises when no device can be opened.
    fn music_open() -> AnyObject {
        ensure_init();
        let mixer = Mixer::new_device(AUDIO_DEVICE_DEFAULT_PLAYBACK, None).or_raise();
        let track = Track::new(&mixer).or_raise();
        native()
            .get_nested_class("Music")
            .wrap_data(MusicBox { mixer, track }, &*MUSIC_WRAPPER)
    }

    // [freq, channels, s16_bytes] for any format SDL_mixer decodes.
    fn music_decode(path: RString) -> Array {
        ensure_init();
        let decoder = AudioDecoder::new(str_of(path), None).or_raise();
        let format = decoder.format().or_raise();
        let spec = AudioSpec { format: AudioFormat::S16, channels: format.channels, freq: format.freq };
        let mut pcm = Vec::new();
        let mut buffer = vec![0u8; 64 * 1024];
        loop {
            let read = decoder.decode(&mut buffer, &spec).or_raise();
            if read == 0 {
                break;
            }
            pcm.extend_from_slice(&buffer[..read]);
        }
        let mut array = Array::with_capacity(3);
        array.push(Fixnum::new(spec.freq as i64));
        array.push(Fixnum::new(spec.channels as i64));
        array.push(RString::from_bytes(&pcm, &Encoding::find("BINARY").unwrap()));
        array
    }
);

methods!(
    RbMusic,
    rtself,

    // `loops`: 0 plays once, -1 forever, n repeats n more times.
    fn music_play(path: RString, loops: AnyObject, fade_in_ms: AnyObject) -> NilClass {
        let data = rtself.get_data(&*MUSIC_WRAPPER);
        let audio = Audio::load(Some(&data.mixer), str_of(path), false).or_raise();
        data.track.set_audio(Some(&audio)).or_raise();
        let options = Properties::new();
        options.set(PROP_PLAY_LOOPS_NUMBER, i64_of(loops, "loops")).or_raise();
        options.set(PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, i64_of(fade_in_ms, "fade in").max(0)).or_raise();
        data.track.play(Some(&options)).or_raise();
        NilClass::new()
    }

    // Nothing loaded is nothing to stop.
    fn music_stop(fade_out_ms: AnyObject) -> NilClass {
        let track = rtself.track();
        if track.audio().or_raise().is_some() {
            let frames = track.ms_to_frames(i64_of(fade_out_ms, "fade out").max(0)).or_raise();
            track.stop(frames).or_raise();
        }
        NilClass::new()
    }

    fn music_pause() -> NilClass {
        rtself.track().pause().or_raise();
        NilClass::new()
    }

    fn music_resume() -> NilClass {
        rtself.track().resume().or_raise();
        NilClass::new()
    }

    fn music_playing() -> Boolean {
        Boolean::new(rtself.track().playing())
    }

    fn music_paused() -> Boolean {
        Boolean::new(rtself.track().paused())
    }

    fn music_set_gain(gain: AnyObject) -> NilClass {
        rtself.track().set_gain(f32_of(gain, "gain")).or_raise();
        NilClass::new()
    }

    fn music_gain() -> Float {
        Float::new(rtself.track().gain().or_raise() as f64)
    }

    fn music_position_ms() -> Fixnum {
        let track = rtself.track();
        if track.audio().or_raise().is_none() {
            return Fixnum::new(0);
        }
        let frames = track.playback_position().or_raise();
        Fixnum::new(track.frames_to_ms(frames).or_raise())
    }

    // nil while nothing is loaded.
    fn music_duration_ms() -> AnyObject {
        match rtself.track().audio().or_raise() {
            Some(audio) => {
                let frames = audio.duration().or_raise();
                Fixnum::new(audio.frames_to_ms(frames).or_raise()).to_any_object()
            }
            None => NilClass::new().to_any_object(),
        }
    }
);

pub fn define(native: &mut Module) {
    native.def_self("decode_audio", music_decode);

    let mut klass = native.define_nested_class("Music", None);
    klass.undef_alloc_func();
    klass.def_self("open", music_open);
    klass.def("play", music_play);
    klass.def("stop", music_stop);
    klass.def("pause", music_pause);
    klass.def("resume", music_resume);
    klass.def("playing?", music_playing);
    klass.def("paused?", music_paused);
    klass.def("gain=", music_set_gain);
    klass.def("gain", music_gain);
    klass.def("position_ms", music_position_ms);
    klass.def("duration_ms", music_duration_ms);
}
