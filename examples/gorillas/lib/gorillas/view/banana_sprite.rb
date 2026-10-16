# frozen_string_literal: true

module Gorillas
  module View
    # A crescent with tapered tips, turned to the banana's current frame
    # (left, up, right, down, as DrawBan's four shapes went round).
    class BananaSprite
      RADIUS = 6.0
      BITE = 3.0 # how far the inner curve is shifted: the crescent's thickness

      # The crescent pointing left, around the origin; built once. The
      # outer and inner arcs meet at the tips, so they come to points.
      def self.shape
        @shape ||= begin
          outer = Rbgame::Geometry.arc_points([0, 0], RADIUS, from: 80, to: 280, segments: 36)
          inner = Rbgame::Geometry.arc_points([BITE, 0], RADIUS - 0.5, from: 100, to: 260, segments: 36)
          (outer + inner.reverse).freeze
        end
      end

      def initialize(banana)
        @banana = banana
      end

      def draw(canvas)
        points = self.class.shape.map do |p|
          turned = p.rotate(@banana.rotation)
          @banana.position + [turned.x, turned.y * Field::ASPECT]
        end
        canvas.polygon(points, Palette::BANANA)
      end
    end
  end
end
