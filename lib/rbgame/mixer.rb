# frozen_string_literal: true

module Rbgame
  # Plays Sounds on an output device. Clips queue back to back; `stop` cuts
  # the queue. A Mixer is given its output, so a game can have more than
  # one and tests can hand it a fake; `Mixer.default` is the one on the
  # default device, opened the first time it is needed.
  #
  # Without a usable audio device the output is Silence: every call is a
  # quiet no-op and `available?` is false, so callers never check for nil.
  class Mixer
    RATE = 44_100
    CHANNELS = 2
    BYTES_PER_SECOND = RATE * CHANNELS * Sound::BYTES_PER_SAMPLE

    # The output of a mixer with nowhere to play.
    class Silence
      def queue(_pcm, _rate, _channels) = nil
      def queued_bytes = 0
      def clear = nil
      def pause = nil
      def resume = nil
      def gain=(_gain)
        nil
      end
    end

    class << self
      def default = @default ||= new(output: open_default_output)

      # Forgets the default mixer; the next use opens the device again.
      def close = @default = nil

      # The class-level API plays on the default mixer.
      %i[available? play stop pause resume volume= queued playing?].each do |name|
        define_method(name) { |*args| default.public_send(name, *args) }
      end

      private

      def open_default_output
        Subsystems.audio.start
        return Silence.new unless Subsystems.audio.started?

        Native.open_audio(RATE, CHANNELS)
      rescue SDLError
        Silence.new
      end
    end

    attr_reader :output

    def initialize(output:)
      @output = output
    end

    def available? = !output.is_a?(Silence)

    # Queues a Sound in its own rate and channel count; SDL converts.
    # Returns false when there is nowhere to play it.
    def play(sound)
      return false unless available?

      output.queue(sound.pcm, sound.rate, sound.channels)
      true
    end

    def stop = tap { output.clear }
    def pause = tap { output.pause }
    def resume = tap { output.resume }

    # 0.0 silent to 1.0 full.
    def volume=(gain)
      output.gain = gain.to_f.clamp(0.0, 1.0)
    end

    # Seconds of sound still queued (approximately).
    def queued = output.queued_bytes / BYTES_PER_SECOND.to_f
    def playing? = queued.positive?
  end
end
