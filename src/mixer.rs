//! `Rbgame::Native::Mixer` and `Rbgame::Native::Track`: SDL_mixer's mixer
//! and tracks, so clips overlap. A mixer is on the default device, or
//! offline (`render` hands back what it would have played) for tests and
//! recordings. Clips cross as signed 16-bit PCM with a rate and channel
//! count; the mixer converts.

use rutie::derive::Bytes;
use rutie::{rubyclass, rubymethods};
use sdl3::audio::{AudioFormat, AudioSpec, AUDIO_DEVICE_DEFAULT_PLAYBACK};
use sdl3::properties::Properties;
use sdl3_mixer::{Audio, Mixer as SdlMixer, StereoGains, Track as SdlTrack, PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, PROP_PLAY_LOOPS_NUMBER};

use crate::music::ensure_init;
use crate::support::{arg_error, Int, NativeResult, Num};

/// Instances come only from `Mixer.open_device` and `Mixer.offline`.
#[rubyclass(path = "Rbgame::Native::Mixer", allocator = false)]
pub struct Mixer {
    mixer: SdlMixer,
    spec: AudioSpec,
}

/// Instances come only from `Mixer#play`.
#[rubyclass(path = "Rbgame::Native::Track", allocator = false)]
pub struct Track {
    track: SdlTrack,
}

fn s16(freq: Int, channels: Int) -> AudioSpec {
    AudioSpec { format: AudioFormat::S16, channels: channels.0 as i32, freq: freq.0 as i32 }
}

// -1.0 (left) to 1.0 (right) as the gains of the two speakers.
fn stereo_gains(pan: f32) -> StereoGains {
    let pan = pan.clamp(-1.0, 1.0);
    StereoGains { left: (1.0 - pan).min(1.0), right: (1.0 + pan).min(1.0) }
}

#[rubymethods]
impl Mixer {
    // On the default device; raises when none can be opened.
    pub fn open_device(freq: Int, channels: Int) -> NativeResult<Mixer> {
        ensure_init();
        let spec = s16(freq, channels);
        let mixer = SdlMixer::new_device(AUDIO_DEVICE_DEFAULT_PLAYBACK, Some(&spec))?;
        Ok(Mixer { mixer, spec })
    }

    // No device: `render` pulls the mixed output.
    pub fn offline(freq: Int, channels: Int) -> NativeResult<Mixer> {
        ensure_init();
        let spec = s16(freq, channels);
        let mixer = SdlMixer::new(&spec)?;
        Ok(Mixer { mixer, spec })
    }

    // Starts `pcm` (S16 at `rate` x `channels`) on a new track and returns it.
    // `loops`: 0 once, -1 forever; `gain` 0..1; `pan` -1..1.
    #[allow(clippy::too_many_arguments)]
    pub fn play(&self, pcm: &Bytes, rate: Int, channels: Int, loops: Int, gain: Num, fade_in_ms: Int, pan: Num) -> NativeResult<Track> {
        let spec = s16(rate, channels);
        if !pcm.0.len().is_multiple_of(2 * spec.channels.max(1) as usize) {
            return arg_error("PCM data must hold whole 16-bit frames");
        }
        let audio = Audio::load_raw(Some(&self.mixer), &pcm.0, &spec)?;
        let track = SdlTrack::new(&self.mixer)?;
        track.set_audio(Some(&audio))?;
        track.set_gain(gain.0 as f32)?;
        if pan.0 != 0.0 {
            track.set_stereo(Some(&stereo_gains(pan.0 as f32)))?;
        }
        let options = Properties::new();
        options.set(PROP_PLAY_LOOPS_NUMBER, loops.0)?;
        options.set(PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER, fade_in_ms.0.max(0))?;
        track.play(Some(&options))?;
        Ok(Track { track })
    }

    pub fn stop_all(&self, fade_out_ms: Int) -> NativeResult<()> {
        Ok(self.mixer.stop_all_tracks(fade_out_ms.0.max(0))?)
    }

    pub fn pause_all(&self) -> NativeResult<()> {
        Ok(self.mixer.pause_all_tracks()?)
    }

    pub fn resume_all(&self) -> NativeResult<()> {
        Ok(self.mixer.resume_all_tracks()?)
    }

    #[ruby(name = "gain=")]
    pub fn set_gain(&self, gain: Num) -> NativeResult<()> {
        Ok(self.mixer.set_gain(gain.0 as f32)?)
    }

    pub fn gain(&self) -> NativeResult<f64> {
        Ok(self.mixer.gain()? as f64)
    }

    pub fn freq(&self) -> i64 {
        self.spec.freq as i64
    }

    pub fn channels(&self) -> i64 {
        self.spec.channels as i64
    }

    // The next `frames` of mixed S16 output; offline mixers only.
    pub fn render(&self, frames: Int) -> NativeResult<Bytes> {
        let frames = frames.0.max(0) as usize;
        let mut buffer = vec![0u8; frames * self.spec.channels.max(1) as usize * 2];
        if !buffer.is_empty() {
            self.mixer.generate(&mut buffer)?;
        }
        Ok(Bytes(buffer))
    }
}

#[rubymethods]
impl Track {
    #[ruby(name = "playing?")]
    pub fn playing(&self) -> bool {
        self.track.playing()
    }

    #[ruby(name = "paused?")]
    pub fn paused(&self) -> bool {
        self.track.paused()
    }

    pub fn stop(&self, fade_out_ms: Int) -> NativeResult<()> {
        let frames = self.track.ms_to_frames(fade_out_ms.0.max(0))?;
        Ok(self.track.stop(frames)?)
    }

    pub fn pause(&self) -> NativeResult<()> {
        Ok(self.track.pause()?)
    }

    pub fn resume(&self) -> NativeResult<()> {
        Ok(self.track.resume()?)
    }

    #[ruby(name = "gain=")]
    pub fn set_gain(&self, gain: Num) -> NativeResult<()> {
        Ok(self.track.set_gain(gain.0 as f32)?)
    }

    pub fn gain(&self) -> NativeResult<f64> {
        Ok(self.track.gain()? as f64)
    }

    #[ruby(name = "pan=")]
    pub fn set_pan(&self, pan: Num) -> NativeResult<()> {
        let gains = if pan.0 == 0.0 { None } else { Some(stereo_gains(pan.0 as f32)) };
        Ok(self.track.set_stereo(gains.as_ref())?)
    }
}

pub fn define() {
    Mixer::define_ruby();
    Track::define_ruby();
}
