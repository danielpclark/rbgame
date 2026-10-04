# frozen_string_literal: true

require "test_helper"

class SynthTest < Minitest::Test
  Synth = Rbgame::Synth

  def test_default_tempo_and_length
    synth = Synth.new("C")
    assert_equal 1, synth.notes.length
    assert_in_delta 0.5, synth.notes.first.seconds # a quarter note at 120 bpm
    assert_in_delta 523.25, synth.notes.first.frequency, 0.5 # O4 C, an octave above middle C
  end

  def test_tempo_length_and_dots
    synth = Synth.new("T240 L8 C C. P8")
    assert_in_delta 0.125, synth.notes[0].seconds
    assert_in_delta 0.1875, synth.notes[1].seconds
    assert_nil synth.notes[2].frequency
  end

  def test_octaves_and_accidentals
    low, high = Synth.new("O3 A O4 A").notes.map(&:frequency)
    assert_in_delta 2.0, high / low, 0.001
    assert_in_delta 440.0, Synth.new("O3 A").notes.first.frequency, 0.5
    assert_in_delta 440.0, Synth.new("O2 A >").notes.first.frequency * 2, 1.0
    assert Synth.new("C#").notes.first.frequency > Synth.new("C").notes.first.frequency
    assert Synth.new("D-").notes.first.frequency < Synth.new("D").notes.first.frequency
  end

  def test_note_numbers
    assert_in_delta 440.0, Synth.new("N46").notes.first.frequency, 0.5
    assert_in_delta 261.63, Synth.new("N37").notes.first.frequency, 0.5 # middle C
    assert_nil Synth.new("N0").notes.first.frequency
  end

  def test_articulation
    assert_in_delta 0.75, Synth.new("MS C").notes.first.sounding / 0.5
    assert_in_delta 1.0, Synth.new("ML C").notes.first.sounding / 0.5
  end

  def test_gorillas_intro_tune_renders
    sound = Synth.play("MBT160O1L8CDEDCDL4ECC")
    assert_in_delta 2.25, sound.duration, 0.01
    assert_equal 22_050, sound.rate
    refute sound.to_samples.all?(&:zero?)
  end

  def test_square_wave_shape
    wave = Rbgame::Synth::SquareWave.new(frequency: 100.0, rate: 1000, seconds: 0.02, sounding: 0.015)
    samples = wave.to_a
    assert_equal 20, samples.length
    assert_equal [Rbgame::Synth::AMPLITUDE] * 5, samples.first(5), "the first half period is high"
    assert_equal [-Rbgame::Synth::AMPLITUDE] * 5, samples[5, 5], "the second half is low"
    assert_equal [0.0] * 5, samples.last(5), "after the sounding part comes silence"
  end

  def test_samples_are_lazy
    synth = Synth.new("T60 L1 C C C C") # four whole notes, 16 seconds
    assert_kind_of Enumerator::Lazy, synth.each_sample
    assert_equal 10, synth.each_sample.first(10).length
  end

  def test_rejects_garbage
    assert_raises(ArgumentError) { Synth.new("C X") }
  end
end
