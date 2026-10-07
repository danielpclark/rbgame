# frozen_string_literal: true

require "test_helper"

# Streams through SDL_mixer on SDL's dummy audio device: the track state is
# real even though nothing is heard.
class MusicTest < Minitest::Test
  Music = Rbgame::Music
  Sound = Rbgame::Sound

  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "tune.wav")
    RbgameTest.write_wav(@path, Sound.from_samples(2000.times.map { |i| Math.sin(i / 7.0) * 0.5 }, rate: 8000))
    Music.stop
  end

  def teardown
    Music.stop
    FileUtils.remove_entry(@dir)
  end

  def test_plays_pauses_and_stops_on_the_default_device
    assert Music.available?
    refute Music.playing?
    assert Music.play(@path)
    assert Music.playing?
    assert_in_delta 0.25, Music.duration, 0.01

    Music.pause
    assert Music.paused?
    refute Music.playing?
    Music.resume
    assert Music.playing?

    Music.stop
    refute Music.playing?
    refute Music.paused?
  end

  def test_loops_fades_and_volume
    assert Music.play(@path, loops: :forever, fade_in: 0.1)
    assert Music.playing?
    Music.volume = 0.25
    assert_in_delta 0.25, Music.volume, 0.001
    Music.volume = 2.0
    assert_in_delta 1.0, Music.volume, 0.001, "clamped"
    Music.stop(fade_out: 0.05)
    assert Music.position >= 0
  end

  def test_a_missing_file_is_an_error
    assert_raises(Rbgame::SDLError) { Music.play(File.join(@dir, "missing.ogg")) }
  end

  def test_silence_is_a_quiet_no_op
    silence = Music::Silence.new
    refute silence.available?
    refute silence.play("anything.mp3", loops: :forever)
    refute silence.playing?
    assert_same silence, silence.stop(fade_out: 1).pause.resume
    assert_nil silence.duration
  end
end
