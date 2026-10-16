# frozen_string_literal: true

module Gorillas
  module View
    # The wind arrow: ten pixels per point of strength (so 99 at 9.9), a
    # one-pixel line with a barbed tip, and the strength written to its
    # right to one decimal place. It sits on the line of the left player's
    # name, just after it, so it stays clear of the aim prompts below; it
    # starts there and its tip is at whichever end the wind blows towards.
    # No wind is no arrow, and "0.0".
    class WindGauge
      PIXELS_PER_UNIT = 10
      BARB = 3
      GAP = 8 # between the name and the arrow, and the arrow and the number

      # `after` is the text the arrow follows: the left player's name.
      def initialize(wind, after:)
        @wind = wind
        @after = after
      end

      def draw(canvas)
        left = Scoreboard::MARGIN + canvas.text_width(@after) + GAP
        right = @wind.calm? ? left - GAP : left + (@wind.strength * PIXELS_PER_UNIT).round
        draw_arrow(canvas, left, right) unless @wind.calm?
        Typography.new(canvas).line(label, at: [right + GAP, Scoreboard::NAME_Y], color: Palette::WIND)
      end

      def label = format("%.1f", @wind.strength)

      private

      def draw_arrow(canvas, left, right)
        y = Scoreboard::NAME_Y + (canvas.text_height / 2)
        tip, barb = @wind.blowing_right? ? [right, -BARB] : [left, BARB]
        Ega.line(canvas, left, y, right, y, Palette::WIND)
        Ega.line(canvas, tip, y, tip + barb, y - BARB, Palette::WIND)
        Ega.line(canvas, tip, y, tip + barb, y + BARB, Palette::WIND)
      end
    end
  end
end
