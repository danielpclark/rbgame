//! `Rbgame::Native::Music`: streamed playback through SDL_mixer, one mixer
//! on the default device with one track. Files are decoded as they play.
//! `Rbgame::Native.decode_audio` reads a whole file into PCM instead, for
//! `Rbgame::Sound`.

use std::sync::Once;

use rutie::{rubyclass, rubymethods, rubymodule};
use sdl3::audio::AUDIO_DEVICE_DEFAULT_PLAYBACK;
use sdl3::properties::Properties;
use sdl3_mixer::{Audio, Mixer, Track, PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, PROP_PLAY_LOOPS_NUMBER};

use crate::support::{Int, NativeResult, Num};

static MIXER_INIT: Once = Once::new();

/// SDL_mixer's `MIX_Init`, once per process.
pub fn ensure_init() {
    MIXER_INIT.call_once(|| {
        let _ = sdl3_mixer::init();
    });
}

/// Instances come only from `Music.open`.
#[rubyclass(path = "Rbgame::Native::Music", allocator = false)]
pub struct Music {
    mixer: Mixer,
    track: Track,
}

#[rubymodule(path = "Rbgame::Native")]
mod functions {
    use rutie::derive::Bytes;
    use sdl3::audio::{AudioFormat, AudioSpec};
    use sdl3_mixer::AudioDecoder;

    use super::ensure_init;
    use crate::support::NativeResult;

    // [freq, channels, s16_bytes] for any format SDL_mixer decodes.
    pub fn decode_audio(path: &str) -> NativeResult<(i64, i64, Bytes)> {
        ensure_init();
        let decoder = AudioDecoder::new(path, None)?;
        let format = decoder.format()?;
        let spec = AudioSpec { format: AudioFormat::S16, channels: format.channels, freq: format.freq };
        let mut pcm = Vec::new();
        let mut buffer = vec![0u8; 64 * 1024];
        loop {
            let read = decoder.decode(&mut buffer, &spec)?;
            if read == 0 {
                break;
            }
            pcm.extend_from_slice(&buffer[..read]);
        }
        Ok((spec.freq as i64, spec.channels as i64, Bytes(pcm)))
    }
}

#[rubymethods]
impl Music {
    // Raises when no device can be opened.
    pub fn open() -> NativeResult<Music> {
        ensure_init();
        let mixer = Mixer::new_device(AUDIO_DEVICE_DEFAULT_PLAYBACK, None)?;
        let track = Track::new(&mixer)?;
        Ok(Music { mixer, track })
    }

    // `loops`: 0 plays once, -1 forever, n repeats n more times.
    pub fn play(&self, path: &str, loops: Int, fade_in_ms: Int) -> NativeResult<()> {
        let audio = Audio::load(Some(&self.mixer), path, false)?;
        self.track.set_audio(Some(&audio))?;
        let options = Properties::new();
        options.set(PROP_PLAY_LOOPS_NUMBER, loops.0)?;
        options.set(PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, fade_in_ms.0.max(0))?;
        Ok(self.track.play(Some(&options))?)
    }

    // Nothing loaded is nothing to stop.
    pub fn stop(&self, fade_out_ms: Int) -> NativeResult<()> {
        if self.track.audio()?.is_some() {
            let frames = self.track.ms_to_frames(fade_out_ms.0.max(0))?;
            self.track.stop(frames)?;
        }
        Ok(())
    }

    pub fn pause(&self) -> NativeResult<()> {
        Ok(self.track.pause()?)
    }

    pub fn resume(&self) -> NativeResult<()> {
        Ok(self.track.resume()?)
    }

    #[ruby(name = "playing?")]
    pub fn playing(&self) -> bool {
        self.track.playing()
    }

    #[ruby(name = "paused?")]
    pub fn paused(&self) -> bool {
        self.track.paused()
    }

    #[ruby(name = "gain=")]
    pub fn set_gain(&self, gain: Num) -> NativeResult<()> {
        Ok(self.track.set_gain(gain.0 as f32)?)
    }

    pub fn gain(&self) -> NativeResult<f64> {
        Ok(self.track.gain()? as f64)
    }

    pub fn position_ms(&self) -> NativeResult<i64> {
        if self.track.audio()?.is_none() {
            return Ok(0);
        }
        let frames = self.track.playback_position()?;
        Ok(self.track.frames_to_ms(frames)?)
    }

    // nil while nothing is loaded.
    pub fn duration_ms(&self) -> NativeResult<Option<i64>> {
        match self.track.audio()? {
            Some(audio) => {
                let frames = audio.duration()?;
                Ok(Some(audio.frames_to_ms(frames)?))
            }
            None => Ok(None),
        }
    }
}

pub fn define() {
    functions::define_ruby();
    Music::define_ruby();
}
