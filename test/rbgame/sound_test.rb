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

  def test_loads_wav_and_other_formats_through_the_decoders
    Dir.mktmpdir do |dir|
      samples = [0.0, 0.5, -0.5, 1.0, -1.0, 0.25]
      wav = File.join(dir, "clip.wav")
      RbgameTest.write_wav(wav, Sound.from_samples(samples, rate: 8000))
      loaded = Sound.load(wav)
      assert_equal 8000, loaded.rate
      assert_equal 1, loaded.channels
      samples.zip(loaded.to_samples) { |want, got| assert_in_delta want, got, 0.001 }

      # Sun AU: a 24-byte header, then 16-bit big-endian PCM.
      au = File.join(dir, "clip.au")
      pcm = samples.map { |x| (x * 32_767).round }.pack("s>*")
      File.binwrite(au, [".snd", 24, pcm.bytesize, 3, 8000, 1].pack("a4N5") + pcm)
      loaded = Sound.load(au)
      assert_equal 8000, loaded.rate
      samples.zip(loaded.to_samples) { |want, got| assert_in_delta want, got, 0.001 }

      assert_raises(Rbgame::SDLError) { Sound.load(File.join(dir, "missing.mp3")) }
    end
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
    channel = Sound.silence(0.1).play(volume: 0.5)
    assert channel.playing?
    Rbgame::Mixer.stop
    refute channel.live?
    refute Rbgame::Mixer.playing?
  end
end
