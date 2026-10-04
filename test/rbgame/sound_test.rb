# frozen_string_literal: true

require "test_helper"

class SoundTest < Minitest::Test
  Sound = Rbgame::Sound

  def test_from_samples
    sound = Sound.from_samples([0.0, 1.0, -1.0, 2.0], rate: 4)
    assert_equal 4, sound.frames
    assert_equal 1.0, sound.duration
    assert_equal [0.0, 1.0, -1.0, 1.0], sound.to_samples
    assert sound.frozen?
  end

  def test_concatenation
    a = Sound.silence(0.5, rate: 100)
    b = Sound.silence(0.25, rate: 100)
    assert_in_delta 0.75, (a + b).duration
    assert_raises(ArgumentError) { a + Sound.silence(1, rate: 200) }
  end

  def test_mixer_on_the_dummy_driver
    RbgameTest.screen
    assert Rbgame::Mixer.available?
    assert Sound.silence(0.1).play
    Rbgame::Mixer.volume = 0.5
    Rbgame::Mixer.stop
    assert_in_delta 0.0, Rbgame::Mixer.queued, 0.01
  end
end
