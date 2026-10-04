# frozen_string_literal: true

require "test_helper"

class MixerTest < Minitest::Test
  # Stands in for Rbgame::Native::AudioOut.
  class FakeOutput
    attr_reader :queued, :gain, :cleared

    def initialize
      @queued = []
      @cleared = 0
    end

    def queue(pcm, rate, channels) = @queued << [pcm.bytesize, rate, channels]
    def queued_bytes = @queued.sum(&:first)
    def clear = @cleared += 1
    def pause; end
    def resume; end
    def gain=(gain)
      @gain = gain
    end
  end

  def test_a_silent_mixer_plays_nothing_and_says_so
    mixer = Rbgame::Mixer.new(output: Rbgame::Mixer::Silence.new)
    refute mixer.available?
    refute mixer.play(Rbgame::Sound.silence(0.1))
    assert_equal 0.0, mixer.queued
    refute mixer.playing?
    mixer.volume = 0.5
    mixer.stop
  end

  def test_sounds_are_queued_in_their_own_format
    output = FakeOutput.new
    mixer = Rbgame::Mixer.new(output: output)
    assert mixer.available?
    assert mixer.play(Rbgame::Sound.silence(0.5, rate: 8000, channels: 1))
    assert_equal [[8000, 8000, 1]], output.queued
    assert_in_delta 8000 / (Rbgame::Mixer::RATE * Rbgame::Mixer::CHANNELS * 2.0), mixer.queued
    assert mixer.playing?
    mixer.stop
    assert_equal 1, output.cleared
  end

  def test_volume_is_clamped
    output = FakeOutput.new
    mixer = Rbgame::Mixer.new(output: output)
    mixer.volume = 3
    assert_equal 1.0, output.gain
    mixer.volume = -1
    assert_equal 0.0, output.gain
  end

  def test_the_default_mixer_opens_lazily_on_the_dummy_driver
    RbgameTest.screen
    assert Rbgame::Mixer.default.available?
    assert Rbgame::Sound.silence(0.05).play
    assert Rbgame::Mixer.available?
  end
end
