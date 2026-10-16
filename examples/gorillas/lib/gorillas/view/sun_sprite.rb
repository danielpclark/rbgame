# frozen_string_literal: true

module Gorillas
  module View
    # The sun as DoSun drew it: a disc, eight rays, two eyes, and a smile
    # that turns into an O when a banana goes through it.
    class SunSprite
      RAYS = [[20, 0], [0, 15], [15, 10], [15, -10], [8, 13], [8, -13], [18, 5], [18, -5]].freeze

      def initialize(sun)
        @sun = sun
      end

      def draw(canvas)
        x, y = @sun.center.to_a
        color = Palette::SUN
        face = Palette::FACE

        Ega.disc(canvas, [x, y], Sun::RADIUS, color)
        RAYS.each { |dx, dy| Ega.line(canvas, x - dx, y - dy, x + dx, y + dy, color) }

        if @sun.shocked?
          Ega.disc(canvas, [x, y + 5], 2.9, face)
        else
          Ega.arc(canvas, [x, y], 8, 210, 330, face)
        end

        [x - 3, x + 3].each do |ex|
          Ega.circle(canvas, [ex, y - 2], 1, face)
          Ega.pset(canvas, ex, y - 2, face)
        end
      end
    end
  end
end
