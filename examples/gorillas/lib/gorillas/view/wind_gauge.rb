# frozen_string_literal: true

module Gorillas
  module View
    # The arrow under the street: its length is the wind's strength.
    class WindGauge
      PIXELS_PER_UNIT = 3

      def initialize(wind)
        @wind = wind
      end

      def draw(canvas)
        return if @wind.calm?

        from = Rbgame::Vector.new(Field::WIDTH / 2, Field::STREET + 10)
        to = from + [@wind.speed * PIXELS_PER_UNIT, 0]
        barb = @wind.blowing_right? ? -2 : 2
        canvas.line(from, to, Palette::WIND)
        canvas.line(to, to + [barb, -2], Palette::WIND)
        canvas.line(to, to + [barb, 2], Palette::WIND)
      end
    end
  end
end
