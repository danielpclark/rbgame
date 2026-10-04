# frozen_string_literal: true

module Gorillas
  # The PLAY strings of GORILLA.BAS, rendered through Rbgame::Synth as the
  # PC-speaker square waves they were. A Jukebox is also a Round listener:
  # events it has a tune for, it plays.
  class Jukebox
    TUNES = {
      intro: "MBT160O1L8CDEDCDL4ECC",
      explosion: "MBO0L32EFGEFDC",
      gorilla_hit: "MBO0L16EFGEFDC",
      victory: "MBT120O1L16EFGEFDC",
      sun_hit: "MBO2L32CDEDC"
    }.freeze

    # For a quiet game: same interface, no sound.
    class Silent
      def play(_name) = false
      def call(_event) = false
    end

    def self.for(sound) = sound ? new : Silent.new

    def initialize
      @sounds = Hash.new { |cache, name| cache[name] = Rbgame::Synth.play(TUNES.fetch(name)) }
    end

    def play(name) = @sounds[name].play
    def call(event) = TUNES.key?(event) && play(event)
    def to_proc = method(:call).to_proc
  end
end
