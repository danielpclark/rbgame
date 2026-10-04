# frozen_string_literal: true

module Gorillas
  module View
    # A crescent, turned to the banana's current frame.
    class BananaSprite
      RADIUS = 7
      THICKNESS = 4

      # The crescent pointing left, around the origin; built once.
      def self.shape
        @shape ||= begin
          outer = Rbgame::Geometry.arc_points([0, 0], RADIUS, from: 90, to: 270, segments: 24)
          inner = Rbgame::Geometry.arc_points([THICKNESS, 0], RADIUS - 1, from: 90, to: 270, segments: 24)
          (outer + inner.reverse).freeze
        end
      end

      def initialize(banana)
        @banana = banana
      end

      def draw(canvas)
        points = self.class.shape.map { |p| @banana.position + p.rotate(@banana.rotation) }
        canvas.polygon(points, Palette::BANANA)
      end
    end
  end
end
