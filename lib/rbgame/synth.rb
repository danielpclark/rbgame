# frozen_string_literal: true

module Rbgame
  # A QBasic PLAY interpreter: the music macro language of the PC speaker,
  # rendered to a Sound as a square wave.
  #
  #   Synth.play("T160 O1 L8 CDEDC D L4 E C C")
  #
  # Supported: notes A-G with # + (sharp) - (flat), lengths (L and per note),
  # dots, octaves O0-6 < >, tempo T, pauses P, note numbers N, MS/MN/ML
  # (staccato/normal/legato) and the no-op MF/MB.
  class Synth
    RATE = 22_050
    AMPLITUDE = 0.25
    SEMITONES = { "C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11 }.freeze
    # QBasic's octave 0 starts at this C (octave 3 holds middle C, as the
    # manual says, and N37 is middle C).
    OCTAVE_ZERO_C = 32.703
    ARTICULATION = { staccato: 0.75, normal: 0.875, legato: 1.0 }.freeze

    TOKEN = /
      (?<note>[A-G])(?<accidental>[#+-])?(?<length>\d+)?(?<dots>\.*) |
      N(?<number>\d+) |
      O(?<octave>\d) |
      L(?<default_length>\d+) |
      T(?<tempo>\d+) |
      P(?<pause>\d+)(?<pause_dots>\.*) |
      M(?<mode>[SNLFB]) |
      (?<shift>[<>]) |
      (?<skip>\s+)
    /xi

    # A note or rest to render: frequency nil means silence.
    Note = Data.define(:frequency, :seconds, :sounding)

    attr_reader :notes

    def self.play(string, rate: RATE) = new(string).to_sound(rate: rate)

    def initialize(string)
      @octave = 4
      @length = 4
      @tempo = 120
      @articulation = :normal
      @notes = parse(string.to_s.upcase)
    end

    def duration = notes.sum(&:seconds)

    def to_sound(rate: RATE)
      Sound.from_samples(samples(rate), rate: rate)
    end

    # Square-wave samples for every note.
    def samples(rate = RATE)
      notes.flat_map do |note|
        total = (note.seconds * rate).round
        sounding = (note.sounding * rate).round
        if note.frequency.nil?
          [0.0] * total
        else
          period = rate / note.frequency
          Array.new(total) { |i| i < sounding && (i % period) < period / 2 ? AMPLITUDE : (i < sounding ? -AMPLITUDE : 0.0) }
        end
      end
    end

    private

    def parse(string)
      notes = []
      position = 0
      while position < string.length
        match = TOKEN.match(string, position)
        raise ArgumentError, "bad PLAY string near #{string[position, 8].inspect}" unless match&.begin(0) == position

        position = match.end(0)
        notes.concat(apply(match))
      end
      notes
    end

    def apply(m)
      if m[:note]
        semitone = SEMITONES[m[:note]] + accidental(m[:accidental])
        [note(frequency_for(@octave, semitone), m[:length] ? m[:length].to_i : @length, m[:dots].length)]
      elsif m[:number]
        number = m[:number].to_i
        freq = number.zero? ? nil : frequency_for((number - 1) / 12, (number - 1) % 12)
        [note(freq, @length, 0)]
      elsif m[:pause]
        [note(nil, m[:pause].to_i, m[:pause_dots].length)]
      else
        update_state(m)
        []
      end
    end

    def update_state(m)
      if m[:octave] then @octave = m[:octave].to_i.clamp(0, 6)
      elsif m[:default_length] then @length = m[:default_length].to_i.clamp(1, 64)
      elsif m[:tempo] then @tempo = m[:tempo].to_i.clamp(32, 255)
      elsif m[:shift] then @octave = (@octave + (m[:shift] == ">" ? 1 : -1)).clamp(0, 6)
      elsif m[:mode]
        case m[:mode]
        when "S" then @articulation = :staccato
        when "N" then @articulation = :normal
        when "L" then @articulation = :legato
        end
      end
    end

    def accidental(mark)
      case mark
      when "#", "+" then 1
      when "-" then -1
      else 0
      end
    end

    def frequency_for(octave, semitone) = OCTAVE_ZERO_C * (2**(((octave * 12) + semitone) / 12.0))

    def note(frequency, length, dots)
      whole = 240.0 / @tempo # a whole note in seconds (4 beats)
      seconds = whole / length
      dots.times { |i| seconds += (whole / length) / (2**(i + 1)) }
      Note.new(frequency: frequency, seconds: seconds, sounding: seconds * ARTICULATION[@articulation])
    end
  end
end
