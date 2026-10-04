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
  #
  # Three parts: a Score reads the string into Notes, a SquareWave turns one
  # Note into samples, and Synth strings them together, lazily.
  class Synth
    RATE = 22_050
    AMPLITUDE = 0.25

    # A note or rest to render: `frequency` nil means silence; `sounding` is
    # the part of `seconds` the note actually sounds (articulation).
    Note = Data.define(:frequency, :seconds, :sounding) do
      def rest? = frequency.nil?
    end

    # Reads PLAY syntax, keeping the octave, length, tempo and articulation
    # state the commands change along the way.
    class Score
      SEMITONES = { "C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11 }.freeze
      # QBasic's octave 0 starts at this C (octave 3 holds middle C, and N37
      # is middle C, as the manual says).
      OCTAVE_ZERO_C = 32.703
      ARTICULATION = { "S" => 0.75, "N" => 0.875, "L" => 1.0 }.freeze
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

      attr_reader :notes

      def initialize(string)
        @octave = 4
        @length = 4
        @tempo = 120
        @articulation = ARTICULATION["N"]
        @notes = read(string.to_s.upcase).freeze
      end

      private

      def read(string)
        notes = []
        position = 0
        while position < string.length
          match = TOKEN.match(string, position)
          raise ArgumentError, "bad PLAY string near #{string[position, 8].inspect}" unless match&.begin(0) == position

          position = match.end(0)
          notes.concat(perform(match))
        end
        notes
      end

      # One command: a note or rest to play, or a change of state.
      def perform(m)
        if m[:note] then [note(pitch(@octave, SEMITONES[m[:note]] + accidental(m[:accidental])), m[:length], m[:dots])]
        elsif m[:number] then [note(numbered_pitch(m[:number].to_i), nil, "")]
        elsif m[:pause] then [note(nil, m[:pause], m[:pause_dots])]
        else
          change_state(m)
          []
        end
      end

      def change_state(m)
        if m[:octave] then @octave = m[:octave].to_i.clamp(0, 6)
        elsif m[:default_length] then @length = m[:default_length].to_i.clamp(1, 64)
        elsif m[:tempo] then @tempo = m[:tempo].to_i.clamp(32, 255)
        elsif m[:shift] then @octave = (@octave + (m[:shift] == ">" ? 1 : -1)).clamp(0, 6)
        elsif m[:mode] then @articulation = ARTICULATION.fetch(m[:mode], @articulation)
        end
      end

      def accidental(mark)
        case mark
        when "#", "+" then 1
        when "-" then -1
        else 0
        end
      end

      def pitch(octave, semitone) = OCTAVE_ZERO_C * (2**(((octave * 12) + semitone) / 12.0))
      def numbered_pitch(number) = number.zero? ? nil : pitch((number - 1) / 12, (number - 1) % 12)

      def note(frequency, length, dots)
        length = length ? length.to_i : @length
        whole = 240.0 / @tempo # four beats
        seconds = whole / length
        dots.to_s.length.times { |i| seconds += (whole / length) / (2**(i + 1)) }
        Note.new(frequency: frequency, seconds: seconds, sounding: seconds * @articulation)
      end
    end

    # The PC speaker's one voice: a square wave for the sounding part of a
    # note, silence for the rest. Enumerable, and lazy when asked.
    class SquareWave
      include Enumerable

      def initialize(frequency:, rate:, seconds:, sounding:)
        @period = frequency && rate / frequency
        @total = (seconds * rate).round
        @sounding = (sounding * rate).round
      end

      def each
        return enum_for(:each) { @total } unless block_given?

        @total.times { |i| yield sample_at(i) }
      end

      private

      def sample_at(i)
        return 0.0 if @period.nil? || i >= @sounding

        (i % @period) < @period / 2 ? AMPLITUDE : -AMPLITUDE
      end
    end

    attr_reader :score

    def self.play(string, rate: RATE) = new(string).to_sound(rate: rate)

    def initialize(string)
      @score = Score.new(string)
    end

    def notes = score.notes
    def duration = notes.sum(&:seconds)

    # Every sample of the tune, produced on demand.
    def each_sample(rate = RATE)
      notes.lazy.flat_map { |note| SquareWave.new(frequency: note.frequency, rate: rate, seconds: note.seconds, sounding: note.sounding).lazy }
    end

    def samples(rate = RATE) = each_sample(rate).to_a
    def to_sound(rate: RATE) = Sound.from_samples(each_sample(rate), rate: rate)
  end
end
