# frozen_string_literal: true

module Gorillas
  # The projectile: a crescent that tumbles through four orientations as
  # it flies, the way DrawBan cycled its four shapes.
  module Banana
    RADIUS = 7
    THICKNESS = 4
    FRAMES = 4

    module_function

    # The crescent as a polygon, pointing left, around the origin.
    def shape
      @shape ||= begin
        outer = Rbgame::Geometry.arc_points([0, 0], RADIUS, from: 90, to: 270, segments: 24)
        inner = Rbgame::Geometry.arc_points([THICKNESS, 0], RADIUS - 1, from: 90, to: 270, segments: 24)
        (outer + inner.reverse).freeze
      end
    end

    def frame_for(time) = (time * 6).floor % FRAMES

    def draw(canvas, position, frame)
      position = Rbgame::Vector.coerce(position)
      angle = frame * 90
      points = shape.map { |p| position + p.rotate(angle) }
      canvas.polygon(points, Palette::BANANA)
    end
  end
end
