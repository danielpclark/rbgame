# frozen_string_literal: true

module Rbgame
  class Canvas
    # Lines and filled or outlined shapes.
    #
    #   screen.fill_rect([10, 10, 50, 20], :red)
    #   screen.circle([100, 100], 30, Color::EGA[14])
    #   screen.line([0, 0], [100, 50], :white, width: 3)
    #   screen.polygon([[0, 0], [40, 0], [20, 30]], "#88ccff")
    module Shapes
      def pixel(pos, color)
        paint(color)
        pos = Vector.coerce(pos)
        renderer.point(pos.x, pos.y)
        self
      end

      def pixels(points, color)
        paint(color)
        renderer.points(points.flat_map { |p| Vector.coerce(p).to_a })
        self
      end

      def line(from, to, color, width: 1)
        return polygon(Geometry.thick_line(from, to, width), color) if width > 1

        paint(color)
        from = Vector.coerce(from)
        to = Vector.coerce(to)
        renderer.line(from.x, from.y, to.x, to.y)
        self
      end

      # A connected run of lines through `points`.
      def lines(points, color, closed: false, width: 1)
        points = points.map { |p| Vector.coerce(p) }
        points << points.first if closed && points.length > 1
        if width > 1
          points.each_cons(2) { |a, b| line(a, b, color, width: width) }
        else
          paint(color)
          renderer.lines(points.flat_map(&:to_a))
        end
        self
      end

      def fill_rect(rect, color)
        paint(color)
        renderer.fill_rect(*Rect.coerce(rect).to_a)
        self
      end

      def stroke_rect(rect, color, width: 1)
        rect = Rect.coerce(rect)
        paint(color)
        if width > 1
          renderer.fill_rects(edges(rect, width).flat_map(&:to_a))
        else
          renderer.rect(*rect.to_a)
        end
        self
      end

      # Filled by default; `fill: false` strokes the outline.
      def rect(rect, color, fill: true, width: 1)
        fill ? fill_rect(rect, color) : stroke_rect(rect, color, width: width)
      end

      def circle(center, radius, color, fill: true, width: 1, segments: nil)
        ellipse_at(center, radius, radius, color, fill: fill, width: width, segments: segments)
      end

      # An ellipse filling `rect`.
      def ellipse(rect, color, fill: true, width: 1, segments: nil)
        rect = Rect.coerce(rect)
        ellipse_at(rect.center, rect.w / 2.0, rect.h / 2.0, color, fill: fill, width: width, segments: segments)
      end

      def ellipse_at(center, rx, ry, color, fill: true, width: 1, segments: nil)
        points = Geometry.arc_points(center, rx, ry, segments: segments)
        points.pop # the closing duplicate
        fill ? fan(center, points, color) : lines(points, color, closed: true, width: width)
        self
      end

      # An arc from `from` to `to` degrees, counter-clockwise, y up.
      def arc(center, radius, from, to, color, width: 1, segments: nil)
        lines(Geometry.arc_points(center, radius, radius, from: from, to: to, segments: segments), color, width: width)
      end

      # A filled (or outlined) polygon; concave shapes are fine.
      def polygon(points, color, fill: true, width: 1)
        points = points.map { |p| Vector.coerce(p) }
        return lines(points, color, closed: true, width: width) unless fill

        indices = Geometry.triangulate(points).flatten
        renderer.geometry(nil, vertices(points, color), indices) unless indices.empty?
        self
      end

      # Raw triangles: `vertices` is [[x, y, color], ...] in threes.
      def triangles(vertices)
        flat = vertices.flat_map do |(pos, color)|
          pos = Vector.coerce(pos)
          [pos.x, pos.y, *Color.coerce(color).to_a, 0, 0]
        end
        renderer.geometry(nil, flat, nil)
        self
      end

      private

      # The four strips of a rectangle's border.
      def edges(rect, width)
        [
          Rect.new(rect.x, rect.y, rect.w, width),
          Rect.new(rect.x, rect.bottom - width, rect.w, width),
          Rect.new(rect.x, rect.y, width, rect.h),
          Rect.new(rect.right - width, rect.y, width, rect.h)
        ]
      end

      # Vertices for the renderer: x, y, r, g, b, a, u, v per point.
      def vertices(points, color)
        rgba = Color.coerce(color).to_a
        points.flat_map { |p| [p.x, p.y, *rgba, 0, 0] }
      end

      # A triangle fan from the centre around the rim.
      def fan(center, rim, color)
        center = Vector.coerce(center)
        last = rim.length
        indices = (1..last).flat_map { |i| [0, i, i == last ? 1 : i + 1] }
        renderer.geometry(nil, vertices([center, *rim], color), indices)
      end
    end

    include Shapes
  end
end
