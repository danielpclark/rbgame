# frozen_string_literal: true

module Rbgame
  # Streamed music through SDL_mixer: MP3, Ogg Vorbis, FLAC, WAV, AIFF, VOC
  # and AU, decoded as they play (and MIDI when the extension is built with
  # the `midi` feature). One piece plays at a time; `play` replaces it.
  #
  #   Music.play("theme.ogg", loops: :forever, fade_in: 2)
  #   Music.volume = 0.5
  #   Music.stop(fade_out: 1)
  #
  # Without an audio device every call is a quiet no-op (Music::Silence),
  # so a game never checks for one.
  module Music
    # The player with nowhere to play.
    class Silence
      def available? = false
      def play(_path, loops: 0, fade_in: 0) = false
      def stop(fade_out: 0) = self
      def pause = self
      def resume = self
      def playing? = false
      def paused? = false
      def volume = 1.0
      def volume=(_gain)
        nil
      end
      def position = 0.0
      def duration = nil
    end

    # The player on the default device.
    class Player
      attr_reader :native

      def initialize(native)
        @native = native
      end

      def available? = true

      # `loops:` is 0 to play once, a count of repeats, or :forever.
      def play(path, loops: 0, fade_in: 0)
        native.play(path.to_s, loops == :forever ? -1 : Integer(loops), millis(fade_in))
        true
      end

      def stop(fade_out: 0) = tap { native.stop(millis(fade_out)) }
      def pause = tap { native.pause }
      def resume = tap { native.resume }
      def playing? = native.playing?
      def paused? = native.paused?
      def volume = native.gain

      def volume=(gain)
        native.gain = gain.clamp(0.0, 1.0)
      end

      # Seconds into the piece.
      def position = native.position_ms / 1000.0

      # Seconds in the piece; nil until something plays.
      def duration = native.duration_ms&.fdiv(1000)

      private

      def millis(seconds) = (seconds * 1000).round
    end

    class << self
      def player = @player ||= open_player

      # Forgets the player; the next use opens the device again.
      def close = @player = nil

      %i[available? play stop pause resume playing? paused? volume volume= position duration].each do |name|
        define_method(name) { |*args, **options| player.public_send(name, *args, **options) }
      end

      private

      def open_player
        Subsystems.audio.start
        return Silence.new unless Subsystems.audio.started?

        Player.new(Native::Music.open)
      rescue SDLError
        Silence.new
      end
    end
  end
end
