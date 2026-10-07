# frozen_string_literal: true

module Rbgame
  # A clip of signed 16-bit PCM. Build one from a sound file, from samples,
  # or with Synth.play from a QBasic PLAY string, then Sound#play it. For
  # long pieces streamed as they play, see Music.
  class Sound
    BYTES_PER_SAMPLE = 2

    attr_reader :pcm, :rate, :channels

    class << self
      # Decodes a whole file: WAV, MP3, Ogg Vorbis, FLAC, AIFF, VOC or AU.
      def load(path)
        rate, channels, pcm = Native.decode_audio(path.to_s)
        new(pcm, rate: rate, channels: channels)
      end

      # Floats between -1.0 and 1.0; any Enumerable, lazy ones included.
      def from_samples(samples, rate: 22_050, channels: 1)
        pcm = samples.map { |s| (s.clamp(-1.0, 1.0) * 32_767).round }.to_a.pack("s<*")
        new(pcm, rate: rate, channels: channels)
      end

      def silence(seconds, rate: 22_050, channels: 1)
        frames = (seconds * rate).round
        new("\0".b * (frames * channels * BYTES_PER_SAMPLE), rate: rate, channels: channels)
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

    def play(mixer = Mixer.default) = mixer.play(self)
    def to_samples = pcm.unpack("s<*").map { |s| s / 32_767.0 }
    def inspect = format("#<Rbgame::Sound %.2fs %dHz x%d>", duration, rate, channels)
  end
end
