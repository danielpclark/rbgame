# frozen_string_literal: true

module Gorillas
  module View
    # The arrow under the street, as MakeCityScape drew it: six pixels per
    # unit of wind, with a two-pixel barb at the tip, along the bottom edge
    # below the score.
    class WindGauge
      PIXELS_PER_UNIT = 6
      BARB = 2

      def initialize(wind)
        @wind = wind
      end

      def draw(canvas)
        return if @wind.calm?

        x = Field::WIDTH / 2
        y = Field::HEIGHT - 3
        tip = x + (@wind.speed * PIXELS_PER_UNIT)
        barb = @wind.blowing_right? ? -BARB : BARB
        Ega.line(canvas, x, y, tip, y, Palette::WIND)
        Ega.line(canvas, tip, y, tip + barb, y - BARB, Palette::WIND)
        Ega.line(canvas, tip, y, tip + barb, y + BARB, Palette::WIND)
      end
    end
  end
end
