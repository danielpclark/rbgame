# frozen_string_literal: true

module Gorillas
  # The PLAY strings of GORILLA.BAS, rendered through Rbgame::Synth as the
  # PC speaker square waves they were.
  module Sounds
    TUNES = {
      intro: "MBT160O1L8CDEDCDL4ECC",
      explosion: "MBO0L32EFGEFDC",
      gorilla_hit: "MBO0L16EFGEFDC",
      victory: "MBT120O1L16EFGEFDC",
      sun_hit: "MBO2L32CDEDC"
    }.freeze

    class << self
      attr_writer :enabled

      def enabled? = @enabled.nil? ? true : @enabled

      def play(name)
        return unless enabled?

        sound(name).play
      end

      def sound(name)
        @sounds ||= {}
        @sounds[name] ||= Rbgame::Synth.play(TUNES.fetch(name))
      end
    end
  end
end
