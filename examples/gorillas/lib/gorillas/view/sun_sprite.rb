# frozen_string_literal: true

module Gorillas
  module View
    # The sun with its rays and its face: a smile, or an O of shock.
    class SunSprite
      RAY = 20
      RAYS = 8

      def initialize(sun)
        @sun = sun
      end

      def draw(canvas)
        center = @sun.center
        RAYS.times { |i| canvas.line(center, center + Rbgame::Vector.polar(i * (360 / RAYS), RAY), Palette::SUN) }
        canvas.circle(center, Sun::RADIUS, Palette::SUN)
        canvas.circle(center + [-4, -3], 1.5, Palette::FACE)
        canvas.circle(center + [4, -3], 1.5, Palette::FACE)
        if @sun.shocked?
          canvas.circle(center + [0, 4], 3, Palette::FACE)
        else
          canvas.arc(center + [0, 1], 6, 200, 340, Palette::FACE)
        end
      end
    end
  end
end
