# frozen_string_literal: true

module Rbgame
  # Frames with their timing: an animated GIF, APNG or ANI file, or Surfaces
  # of your own. `at` answers the frame showing at a moment, looping, so a
  # game draws `animation.at(clock.elapsed)` and nothing else.
  #
  #   walk = Animation.load("walk.gif")
  #   walk.at(elapsed).with_texture(screen) { |sprite| screen.draw(sprite, at: pos) }
  #
  #   blink = Animation[eyes_open, eyes_shut, duration: 0.4]
  #   blink.save("blink.gif")
  class Animation
    include Enumerable

    Frame = Data.define(:surface, :duration) do
      def size = surface.size
    end

    class << self
      def load(path)
        new(Native.load_animation(path.to_s).map { |surface, ms| Frame.new(surface: Surface.new(surface), duration: ms / 1000.0) })
      end

      # Surfaces shown `duration:` seconds each.
      def [](*surfaces, duration:) = new(surfaces.map { |surface| Frame.new(surface: surface, duration: duration) })
    end

    attr_reader :frames

    def initialize(frames)
      @frames = frames.to_a.freeze
    end

    def each(&) = frames.each(&)
    def count = frames.size
    def empty? = frames.empty?
    def size = frames.first&.size || Vector::ZERO

    # Seconds for one run through.
    def duration = frames.sum(&:duration)

    # The Surface showing `seconds` in; past the end it loops (or stays on
    # the last frame with `loop: false`). Nil for an empty animation.
    def at(seconds, loop: true)
      return nil if empty?

      seconds = loop ? seconds % duration : seconds.clamp(0, duration)
      frame = frames.find { |f| (seconds -= f.duration).negative? } || frames.last
      frame.surface
    end

    # Writes the format the extension names: GIF, APNG (.png) or ANI.
    def save(path)
      Native.save_animation(path.to_s, frames.map { |f| f.surface.native }, frames.map { |f| (f.duration * 1000).round })
      self
    end

    def inspect = "#<Rbgame::Animation #{count} frames, #{duration.round(3)}s>"
  end
end
