# frozen_string_literal: true

module Gorillas
  module View
    # QBasic's drawing statements as GORILLA.BAS used them on SCREEN 9,
    # whose 640x350 pixels were taller than wide on a 4:3 monitor. CIRCLE
    # compensated by drawing ellipses that looked round; the field is
    # stretched to 4:3 the same way here (Field::ASPECT), so these draw
    # with the same squash and the original's shapes come out as they did.
    #
    # Angles are degrees, counter-clockwise with y up, as CIRCLE's radians
    # were.
    module Ega
      module_function

      # CIRCLE (x, y), r, color, from, to, drawn `thickness` times, each one
      # pixel to the right of the last, as DrawGorilla thickened its arcs.
      def arc(canvas, center, radius, from, to, color, thickness: 1)
        center = Rbgame::Vector.coerce(center)
        to += 360 if to < from
        thickness.times do |i|
          points = Rbgame::Geometry.arc_points(center + [i, 0], radius, radius * Field::ASPECT, from: from, to: to)
          canvas.lines(points, color)
        end
      end

      # CIRCLE (x, y), r, color: the outline.
      def circle(canvas, center, radius, color)
        canvas.ellipse(ellipse_rect(center, radius), color, fill: false)
      end

      # CIRCLE then PAINT: the filled disc.
      def disc(canvas, center, radius, color)
        canvas.ellipse(ellipse_rect(center, radius), color)
      end

      # LINE (x0, y0)-(x1, y1), color, BF: both corners inside the box.
      def box(canvas, x0, y0, x1, y1, color)
        x0, x1 = x1, x0 if x1 < x0
        y0, y1 = y1, y0 if y1 < y0
        canvas.fill_rect([x0, y0, x1 - x0 + 1, y1 - y0 + 1], color)
      end

      # LINE (x0, y0)-(x1, y1), color
      def line(canvas, x0, y0, x1, y1, color) = canvas.line([x0, y0], [x1, y1], color)

      # PSET (x, y), color
      def pset(canvas, x, y, color) = canvas.pixel([x, y], color)

      def ellipse_rect(center, radius)
        center = Rbgame::Vector.coerce(center)
        ry = radius * Field::ASPECT
        Rbgame::Rect.new(center.x - radius, center.y - ry, radius * 2, ry * 2)
      end
    end
  end
end
