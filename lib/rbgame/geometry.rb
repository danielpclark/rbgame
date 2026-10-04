# frozen_string_literal: true

module Rbgame
  # Pure geometry helpers behind Canvas: polygon triangulation, circle and
  # arc sampling, thick-line outlines. No SDL in here, so it's all testable.
  module Geometry
    module_function

    # Points on a circle (or ellipse with radii rx, ry), `segments` of them,
    # starting at `from` degrees and going counter-clockwise to `to`.
    def arc_points(center, rx, ry = rx, from: 0, to: 360, segments: nil)
      center = Vector.coerce(center)
      segments ||= segments_for([rx, ry].max)
      sweep = to - from
      steps = [(segments * (sweep.abs / 360.0)).ceil, 1].max
      (0..steps).map do |i|
        angle = (from + (sweep * i / steps.to_f)) * Math::PI / 180
        Vector.new(center.x + (Math.cos(angle) * rx), center.y - (Math.sin(angle) * ry))
      end
    end

    # Enough segments for a smooth circle of this radius.
    def segments_for(radius) = [12, (radius.abs * 1.5).ceil].max.clamp(12, 180)

    # Signed area; positive for counter-clockwise in a y-down space.
    def signed_area(points)
      points.each_with_index.sum do |p, i|
        q = points[(i + 1) % points.length]
        (p.x * q.y) - (q.x * p.y)
      end / 2.0
    end

    # Triangle indices for a simple polygon (ear clipping; convex or concave,
    # no self-intersection). Returns an Array of [i, j, k] index triples.
    def triangulate(points)
      points = points.map { |p| Vector.coerce(p) }
      return [] if points.length < 3

      indices = (0...points.length).to_a
      indices.reverse! if signed_area(points).negative?
      triangles = []
      guard = 0

      while indices.length > 3 && guard < points.length * points.length
        guard += 1
        ear_found = false
        indices.length.times do |n|
          i0, i1, i2 = indices[n - 1], indices[n], indices[(n + 1) % indices.length]
          a, b, c = points[i0], points[i1], points[i2]
          next unless convex?(a, b, c)
          next if indices.any? { |other| ![i0, i1, i2].include?(other) && inside_triangle?(points[other], a, b, c) }

          triangles << [i0, i1, i2]
          indices.delete_at(n)
          ear_found = true
          break
        end
        break unless ear_found
      end

      triangles << indices.first(3) if indices.length == 3
      triangles
    end

    def convex?(a, b, c) = cross(a, b, c).positive?

    def cross(a, b, c) = ((b.x - a.x) * (c.y - a.y)) - ((b.y - a.y) * (c.x - a.x))

    def inside_triangle?(p, a, b, c)
      d1, d2, d3 = cross(a, b, p), cross(b, c, p), cross(c, a, p)
      has_neg = d1.negative? || d2.negative? || d3.negative?
      has_pos = d1.positive? || d2.positive? || d3.positive?
      !(has_neg && has_pos)
    end

    # The four corners of a line segment given a stroke width.
    def thick_line(from, to, width)
      from = Vector.coerce(from)
      to = Vector.coerce(to)
      direction = (to - from).normalize
      normal = Vector.new(-direction.y, direction.x) * (width / 2.0)
      [from + normal, to + normal, to - normal, from - normal]
    end
  end
end
