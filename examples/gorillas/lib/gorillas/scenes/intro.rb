# frozen_string_literal: true

module Gorillas
  module Scenes
    # The title card, with the tune.
    class Intro < Base
      UNATTENDED_SECONDS = 2.5
      TITLE = "R u b y   G O R I L L A S"
      MISSION = [
        "Your mission is to hit your opponent with the exploding",
        "banana by varying the angle and power of your throw, taking",
        "into account wind speed, gravity, and the city skyline.",
        "The wind speed is shown by a directional arrow at the bottom",
        "of the playing field, its length relative to its strength."
      ].freeze

      def enter = jukebox.play(:intro)
      def handle(event) = (Setup.new(game) if any_key?(event))

      def draw(canvas)
        canvas.fill(Palette::SKY)
        text = typography(canvas)
        text.title(TITLE, y: 40, scale: 3)
        text.title("an rbgame demo, after GORILLA.BAS (1990)", y: 80, scale: 1, color: Palette::TEXT_DIM)
        text.paragraph(MISSION, y: 130)
        text.title("Press any key to continue", y: 250, scale: 1, color: View::Blink.on? ? Palette::TEXT : Palette::TEXT_DIM)
        View::SunSprite.new(Sun.new).draw(canvas)
        View::GorillaSprite.new(Gorilla.new(feet: [200, 330], facing: :right, pose: :left_up)).draw(canvas)
        View::GorillaSprite.new(Gorilla.new(feet: [440, 330], facing: :left, pose: :right_up)).draw(canvas)
        View::BananaSprite.new(Banana.new(position: [320, 300], flight_time: elapsed)).draw(canvas)
      end

      private

      def tick(_dt)
        Setup.new(game) if controller.unattended? && elapsed >= UNATTENDED_SECONDS
      end
    end
  end
end
