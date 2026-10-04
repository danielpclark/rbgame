//! `Rbgame::Native::AudioOut`: a playback stream on the default device.
//! Ruby queues signed 16-bit PCM; SDL converts and resamples.

use rutie::{AnyObject, Array, Encoding, Fixnum, Module, NilClass, Object, RString};
use sdl3::audio::{AudioFormat, AudioSpec, AudioStream};

use crate::support::{arg, f32_of, i32_of, native, raise_arg, str_of, OrRaise};

pub struct AudioOutBox {
    stream: AudioStream,
    device_spec: AudioSpec,
}

wrappable_struct!(AudioOutBox, AudioOutWrapper, AUDIO_OUT_WRAPPER);
native_class!(RbAudioOut, "AudioOut");

fn s16(freq: i32, channels: i32) -> AudioSpec {
    AudioSpec { format: AudioFormat::S16, channels, freq }
}

/// WAV data converted to S16 at its own rate and channel count.
fn wav_as_s16(spec: AudioSpec, bytes: &[u8]) -> (AudioSpec, Vec<u8>) {
    let target = s16(spec.freq, spec.channels);
    if spec.format == AudioFormat::S16 {
        return (target, bytes.to_vec());
    }
    let stream = AudioStream::new(Some(&spec), Some(&target)).or_raise();
    stream.put_data(bytes).or_raise();
    stream.flush();
    let mut out = vec![0u8; stream.available().max(0) as usize];
    let read = stream.get_data(&mut out).or_raise();
    out.truncate(read);
    (target, out)
}

methods!(
    AnyObject,
    _rtself,

    fn aud_open(freq: AnyObject, channels: AnyObject) -> AnyObject {
        let device_spec = s16(i32_of(freq, "freq"), i32_of(channels, "channels"));
        let stream = sdl3::audio::open_audio_device_stream(
            sdl3::audio::AUDIO_DEVICE_DEFAULT_PLAYBACK,
            Some(&device_spec),
            None::<fn(&AudioStream, i32, i32)>,
        )
        .or_raise();
        stream.resume_device().or_raise();
        native()
            .get_nested_class("AudioOut")
            .wrap_data(AudioOutBox { stream, device_spec }, &*AUDIO_OUT_WRAPPER)
    }

    // [freq, channels, s16_bytes]
    fn aud_load_wav(path: RString) -> Array {
        let (spec, bytes) = sdl3::audio::load_wav(str_of(path)).or_raise();
        let (spec, bytes) = wav_as_s16(spec, &bytes);
        let mut array = Array::with_capacity(3);
        array.push(Fixnum::new(spec.freq as i64));
        array.push(Fixnum::new(spec.channels as i64));
        array.push(RString::from_bytes(&bytes, &Encoding::find("BINARY").unwrap()));
        array
    }
);

methods!(
    RbAudioOut,
    rtself,

    fn aud_queue(bytes: RString, freq: AnyObject, channels: AnyObject) -> NilClass {
        let bytes = arg(bytes);
        let source = s16(i32_of(freq, "freq"), i32_of(channels, "channels"));
        let data = bytes.to_bytes_unchecked();
        if !data.len().is_multiple_of(2 * source.channels.max(1) as usize) {
            raise_arg("PCM data must hold whole 16-bit frames");
        }
        let out = rtself.get_data(&*AUDIO_OUT_WRAPPER);
        out.stream.set_format(Some(&source), None).or_raise();
        out.stream.put_data(data).or_raise();
        NilClass::new()
    }

    fn aud_queued_bytes() -> Fixnum {
        Fixnum::new(rtself.get_data(&*AUDIO_OUT_WRAPPER).stream.queued().max(0) as i64)
    }

    fn aud_clear() -> NilClass {
        rtself.get_data(&*AUDIO_OUT_WRAPPER).stream.clear();
        NilClass::new()
    }

    fn aud_pause() -> NilClass {
        rtself.get_data(&*AUDIO_OUT_WRAPPER).stream.pause_device().or_raise();
        NilClass::new()
    }

    fn aud_resume() -> NilClass {
        rtself.get_data(&*AUDIO_OUT_WRAPPER).stream.resume_device().or_raise();
        NilClass::new()
    }

    fn aud_set_gain(gain: AnyObject) -> NilClass {
        rtself.get_data(&*AUDIO_OUT_WRAPPER).stream.set_gain(f32_of(gain, "gain")).or_raise();
        NilClass::new()
    }

    fn aud_freq() -> Fixnum {
        Fixnum::new(rtself.get_data(&*AUDIO_OUT_WRAPPER).device_spec.freq as i64)
    }

    fn aud_channels() -> Fixnum {
        Fixnum::new(rtself.get_data(&*AUDIO_OUT_WRAPPER).device_spec.channels as i64)
    }

);

pub fn define(native: &mut Module) {
    native.def_self("open_audio", aud_open);
    native.def_self("load_wav", aud_load_wav);

    let mut klass = native.define_nested_class("AudioOut", None);
    // Instances come only from Rust (`wrap_data`), never from `AudioOut.new`.
    klass.undef_alloc_func();
    klass.define(|klass| {
        klass.def("queue", aud_queue);
        klass.def("queued_bytes", aud_queued_bytes);
        klass.def("clear", aud_clear);
        klass.def("pause", aud_pause);
        klass.def("resume", aud_resume);
        klass.def("gain=", aud_set_gain);
        klass.def("freq", aud_freq);
        klass.def("channels", aud_channels);
    });
}
