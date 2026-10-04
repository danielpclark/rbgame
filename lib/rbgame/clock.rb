# frozen_string_literal: true

module Rbgame
  # Frame timing.
  #
  #   clock = Clock.new
  #   loop do
  #     seconds = clock.tick(60)  # since the last tick, held to 60 fps
  #     clock.fps                 # smoothed frames per second
  #   end
  class Clock
    NS_PER_SECOND = 1_000_000_000

    attr_reader :frame_time, :frames

    def initialize(smoothing: 10)
      @smoothing = smoothing
      @last_ns = Clock.now_ns
      @started_ns = @last_ns
      @frame_time = 0.0
      @frames = 0
      @recent = []
    end

    # Seconds since the last tick. With `fps`, sleeps first so the frame
    # lasts at least 1/fps.
    def tick(fps = nil)
      if fps&.positive?
        target_ns = @last_ns + (NS_PER_SECOND / fps.to_f).round
        remaining = target_ns - Clock.now_ns
        Native.delay_precise_ns(remaining) if remaining.positive?
      end

      now = Clock.now_ns
      @frame_time = (now - @last_ns) / NS_PER_SECOND.to_f
      @last_ns = now
      @frames += 1
      @recent << @frame_time
      @recent.shift while @recent.length > @smoothing
      @frame_time
    end

    # Smoothed frames per second over the last few frames.
    def fps
      return 0.0 if @recent.empty?

      total = @recent.sum
      total.zero? ? 0.0 : @recent.length / total
    end

    # Seconds since this clock was created.
    def elapsed = (Clock.now_ns - @started_ns) / NS_PER_SECOND.to_f

    class << self
      def now_ns = Native.ticks_ns
      def now = now_ns / NS_PER_SECOND.to_f

      # Sleeps for `seconds` without holding the GVL.
      def sleep(seconds) = Native.delay_ns((seconds * NS_PER_SECOND).round)
    end
  end
end
