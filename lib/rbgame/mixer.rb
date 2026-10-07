# frozen_string_literal: true

module Rbgame
  # Plays Sounds through SDL_mixer: as many at once as a game likes, each on
  # its own Channel with volume, pan, loops and fades. `Mixer.default` is
  # the one on the default device, opened the first time it is needed; a
  # game can open more, and `Mixer.offline` mixes into a Sound instead of
  # a device, which is how tests and recordings hear what was played.
  #
  #   explosion.play                              # on Mixer.default
  #   channel = engine.play(loops: :forever, volume: 0.4, pan: -0.5)
  #   channel.stop(fade_out: 0.5)
  #
  # Without a usable audio device the mixer is Silence: every call is a
  # quiet no-op, `play` answers Channel::None, and `available?` is false,
  # so callers never check for nil.
  class Mixer
    RATE = 44_100
    CHANNELS = 2

    # One playing Sound.
    class Channel
      attr_reader :native

      def initialize(native)
        @native = native
      end

      def playing? = native.playing?
      def paused? = native.paused?
      def live? = playing? || paused?
      def stop(fade_out: 0) = tap { native.stop(Mixer.millis(fade_out)) }
      def pause = tap { native.pause }
      def resume = tap { native.resume }
      def volume = native.gain

      def volume=(gain)
        native.gain = gain.to_f.clamp(0.0, 1.0)
      end

      # -1.0 left, 0.0 centre, 1.0 right.
      def pan=(pan)
        native.pan = pan.to_f.clamp(-1.0, 1.0)
      end

      # The channel of a sound that never played.
      class None
        def playing? = false
        def paused? = false
        def live? = false
        def stop(fade_out: 0) = self
        def pause = self
        def resume = self
        def volume = 0.0
        def volume=(_gain)
          nil
        end
        def pan=(_pan)
          nil
        end
      end
    end

    # The mixer with nowhere to play.
    class Silence
      def available? = false
      def play(_sound, loops: 0, volume: 1.0, fade_in: 0, pan: 0.0) = Channel::None.new
      def stop(fade_out: 0) = self
      def pause = self
      def resume = self
      def volume = 1.0
      def volume=(_gain)
        nil
      end
      def channels = []
      def playing? = false
    end

    class << self
      def default = @default ||= open_default

      # Forgets the default mixer; the next use opens the device again.
      def close = @default = nil

      # A mixer with no device: `render` pulls what it mixed.
      def offline(rate: RATE, channels: CHANNELS) = new(Native::Mixer.offline(rate, channels))

      # The class-level API plays on the default mixer.
      %i[available? play stop pause resume volume volume= channels playing?].each do |name|
        define_method(name) { |*args, **options| default.public_send(name, *args, **options) }
      end

      def millis(seconds) = (seconds * 1000).round

      private

      def open_default
        Subsystems.audio.start
        return Silence.new unless Subsystems.audio.started?

        new(Native::Mixer.open_device(RATE, CHANNELS))
      rescue SDLError
        Silence.new
      end
    end

    attr_reader :native

    def initialize(native)
      @native = native
      @channels = []
    end

    def available? = true

    # Starts `sound` on a Channel of its own, in its own rate and channel
    # count; the mixer converts. `loops:` is 0, a count, or :forever.
    def play(sound, loops: 0, volume: 1.0, fade_in: 0, pan: 0.0)
      track = native.play(sound.pcm, sound.rate, sound.channels, loops == :forever ? -1 : Integer(loops),
                          volume.to_f.clamp(0.0, 1.0), Mixer.millis(fade_in), pan.to_f.clamp(-1.0, 1.0))
      Channel.new(track).tap { |channel| @channels << channel }
    end

    def stop(fade_out: 0) = tap { native.stop_all(Mixer.millis(fade_out)) }
    def pause = tap { native.pause_all }
    def resume = tap { native.resume_all }
    def volume = native.gain

    # 0.0 silent to 1.0 full, over every channel.
    def volume=(gain)
      native.gain = gain.to_f.clamp(0.0, 1.0)
    end

    # The channels still playing or paused.
    def channels
      @channels.select!(&:live?)
      @channels.dup
    end

    def playing? = channels.any?(&:playing?)
    def rate = native.freq
    def channel_count = native.channels

    # Offline mixers: the next `seconds` of mixed output as a Sound.
    def render(seconds)
      frames = (seconds * rate).round
      Sound.new(native.render(frames), rate: rate, channels: channel_count)
    end

    def inspect = "#<Rbgame::Mixer #{rate}Hz x#{channel_count}, #{channels.size} playing>"
  end
end
