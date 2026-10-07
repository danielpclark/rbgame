# frozen_string_literal: true

require "test_helper"

# Mixes offline, so the tests hear exactly what SDL_mixer produced, and
# on the dummy device for the default mixer.
class MixerTest < Minitest::Test
  Mixer = Rbgame::Mixer
  Sound = Rbgame::Sound

  RATE = 8000

  # A flat clip at `level` for `seconds`, mono at the mixer's rate.
  def flat(level, seconds)
    Sound.from_samples([level] * (seconds * RATE).round, rate: RATE)
  end

  def levels(sound, at_seconds)
    frame = (at_seconds * sound.rate).round * sound.channels
    sound.to_samples[frame, sound.channels]
  end

  def setup
    @mixer = Mixer.offline(rate: RATE, channels: 1)
  end

  def test_sounds_overlap
    @mixer.play(flat(0.25, 0.3))
    @mixer.play(flat(0.25, 0.1))
    assert_equal 2, @mixer.channels.size
    mixed = @mixer.render(0.3)
    assert_in_delta 0.5, levels(mixed, 0.05).first, 0.01, "both clips sound together"
    assert_in_delta 0.25, levels(mixed, 0.2).first, 0.01, "the short one has finished"
    assert_equal 1, @mixer.channels.size
  end

  def test_volume_and_pan_shape_a_channel
    stereo = Mixer.offline(rate: RATE, channels: 2)
    stereo.play(flat(0.8, 0.1), volume: 0.5, pan: -1.0)
    left, right = levels(stereo.render(0.1), 0.05)
    assert_in_delta 0.4, left, 0.02
    assert_in_delta 0.0, right, 0.02, "panned hard left"

    stereo.play(flat(0.8, 0.1), volume: 3)
    assert_in_delta 0.8, levels(stereo.render(0.1), 0.05).first, 0.02, "volume clamps to 1.0"
  end

  def test_stop_pause_and_resume
    channel = @mixer.play(flat(0.5, 1.0))
    assert channel.playing?
    channel.pause
    assert channel.paused?
    assert_in_delta 0.0, levels(@mixer.render(0.1), 0.05).first, 0.01, "paused is silent"
    channel.resume
    assert channel.playing?
    @mixer.stop
    refute channel.live?
    assert_empty @mixer.channels
    refute @mixer.playing?
  end

  def test_loops_keep_a_sound_going
    @mixer.play(flat(0.5, 0.05), loops: :forever)
    mixed = @mixer.render(0.5)
    assert_in_delta 0.5, levels(mixed, 0.45).first, 0.01
    assert @mixer.playing?
  end

  def test_mixer_volume_applies_to_everything
    @mixer.play(flat(0.5, 0.1))
    @mixer.volume = 0.5
    assert_in_delta 0.25, levels(@mixer.render(0.1), 0.05).first, 0.01
  end

  def test_silence_plays_nothing_and_says_so
    silence = Mixer::Silence.new
    refute silence.available?
    channel = silence.play(Sound.silence(0.1), loops: :forever)
    refute channel.live?
    assert_same channel, channel.stop(fade_out: 1).pause.resume
    assert_equal [], silence.channels
    refute silence.playing?
    silence.volume = 0.5
  end

  def test_the_default_mixer_opens_lazily_on_the_dummy_driver
    RbgameTest.screen
    assert Mixer.default.available?
    channel = Sound.silence(0.05).play
    assert_kind_of Mixer::Channel, channel
    assert Mixer.available?
    Mixer.stop
  end
end
