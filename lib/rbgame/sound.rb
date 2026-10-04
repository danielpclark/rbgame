# frozen_string_literal: true

module Rbgame
  # A clip of signed 16-bit PCM. Build one from a WAV file, from samples, or
  # with Synth.play from a QBasic PLAY string, then Sound#play it.
  class Sound
    BYTES_PER_SAMPLE = 2

    attr_reader :pcm, :rate, :channels

    class << self
      def load(path)
        rate, channels, pcm = Native.load_wav(path.to_s)
        new(pcm, rate: rate, channels: channels)
      end

      # Floats between -1.0 and 1.0.
      def from_samples(samples, rate: 22_050, channels: 1)
        pcm = samples.map { |s| (s.clamp(-1.0, 1.0) * 32_767).round }.pack("s<*")
        new(pcm, rate: rate, channels: channels)
      end

      def silence(seconds, rate: 22_050, channels: 1)
        new("\0".b * (seconds * rate * channels * BYTES_PER_SAMPLE).round, rate: rate, channels: channels)
      end
    end

    def initialize(pcm, rate:, channels: 1)
      @pcm = pcm.b.freeze
      @rate = rate
      @channels = channels
      freeze
    end

    def frames = pcm.bytesize / (BYTES_PER_SAMPLE * channels)
    def duration = frames / rate.to_f
    def empty? = pcm.empty?

    # Appends another clip; it must share the rate and channel count.
    def +(other)
      unless other.rate == rate && other.channels == channels
        raise ArgumentError, "cannot join #{rate} Hz x#{channels} with #{other.rate} Hz x#{other.channels}"
      end

      Sound.new(pcm + other.pcm, rate: rate, channels: channels)
    end

    def play = Mixer.play(self)
    def to_samples = pcm.unpack("s<*").map { |s| s / 32_767.0 }
    def inspect = format("#<Rbgame::Sound %.2fs %dHz x%d>", duration, rate, channels)
  end

  # Plays Sounds on the default output device. Clips queue back to back;
  # Mixer.stop cuts the queue.
  #
  # Without a usable audio device (a headless box, the dummy driver) every
  # method is a quiet no-op and Mixer.available? is false.
  module Mixer
    RATE = 44_100
    CHANNELS = 2

    class << self
      def available?
        open
        !@out.nil?
      end

      def open
        return @out if defined?(@tried)

        @tried = true
        Rbgame.init(video: false, audio: true) unless Rbgame.initialized?(:audio)
        @out = Rbgame.initialized?(:audio) ? Native.open_audio(RATE, CHANNELS) : nil
      rescue Rbgame::SDLError
        @out = nil
      end

      def play(sound)
        return false unless available?

        @out.queue(sound.pcm, sound.rate, sound.channels)
        true
      end

      def stop = @out&.clear
      def pause = @out&.pause
      def resume = @out&.resume

      # 0.0 silent to 1.0 full.
      def volume=(gain)
        @out&.gain = gain.to_f.clamp(0.0, 1.0)
      end

      # Seconds of sound still queued (approximately).
      def queued = @out ? @out.queued_bytes / (RATE * CHANNELS * 2).to_f : 0.0
      def playing? = queued.positive?

      def close
        @out = nil
        remove_instance_variable(:@tried) if defined?(@tried)
      end
    end
  end
end
