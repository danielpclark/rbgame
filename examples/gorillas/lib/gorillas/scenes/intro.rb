# frozen_string_literal: true

module Gorillas
  module Scenes
    # The title card, with the tune.
    class Intro < Base
      AUTOPLAY_SECONDS = 2.5

      def enter
        @elapsed = 0.0
        Sounds.play(:intro)
      end

      def handle(event)
        Setup.new(game) if any_key?(event)
      end

      def update(dt)
        @elapsed += dt
        Setup.new(game) if options.autoplay && @elapsed >= AUTOPLAY_SECONDS
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        title(canvas, "R u b y   G O R I L L A S", y: 40, scale: 3)
        title(canvas, "an rbgame demo, after GORILLA.BAS (1990)", y: 80, scale: 1, color: Palette::TEXT_DIM)
        paragraph(canvas, [
          "Your mission is to hit your opponent with the exploding",
          "banana by varying the angle and power of your throw, taking",
          "into account wind speed, gravity, and the city skyline.",
          "The wind speed is shown by a directional arrow at the bottom",
          "of the playing field, its length relative to its strength."
        ], y: 130)
        title(canvas, "Press any key to continue", y: 250, scale: 1, color: (@elapsed * 2).floor.even? ? Palette::TEXT : Palette::TEXT_DIM)
        Sun.new.draw(canvas)
        Gorilla.new(feet: [200, 330], facing: :right, pose: :left_up).draw(canvas)
        Gorilla.new(feet: [440, 330], facing: :left, pose: :right_up).draw(canvas)
        Banana.draw(canvas, [320, 300], (@elapsed * 6).floor % 4)
      end
    end
  end
end
