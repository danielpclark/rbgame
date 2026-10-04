# frozen_string_literal: true

module Rbgame
  # An immutable axis-aligned rectangle. Where pygame's Rect mutates in
  # place, every Rbgame::Rect method returns a new Rect, so rectangles can be
  # shared freely and used as Hash keys.
  #
  #   r = Rect.new(10, 20, 100, 50)
  #   r.center                 # => Vector[60, 45]
  #   r.move(5, 0)             # => Rect[15, 20, 100, 50]
  #   r.centered_at([0, 0])    # => Rect[-50, -25, 100, 50]
  #   r.inflate(10, 10)        # 5 px bigger on every side
  #   r.collide?(other)        # overlap test
  #   r.contains?([12, 25])    # point test
  Rect = Data.define(:x, :y, :w, :h) do
    class << self
      remove_method :[] # Data's own `[]` is `new`; ours coerces

      def [](*args) = coerce(args.length == 1 ? args.first : args)

      def coerce(value)
        case value
        when Rect then value
        when Array
          case value.length
          when 4 then new(*value)
          when 2 then new(*Vector.coerce(value[0]).to_a, *Vector.coerce(value[1]).to_a)
          else raise ArgumentError, "a Rect array needs 4 numbers or [position, size]"
          end
        when Hash then new(**value)
        else raise TypeError, "cannot convert #{value.class} to #{name}"
        end
      end

      def from_center(center, size)
        center = Vector.coerce(center)
        size = Vector.coerce(size)
        new(center.x - (size.x / 2.0), center.y - (size.y / 2.0), size.x, size.y)
      end

      def at(position, size)
        position = Vector.coerce(position)
        size = Vector.coerce(size)
        new(position.x, position.y, size.x, size.y)
      end

      # The smallest rectangle around a set of points.
      def bounding(points)
        points = points.map { |p| Vector.coerce(p) }
        raise ArgumentError, "need at least one point" if points.empty?

        xs = points.map(&:x)
        ys = points.map(&:y)
        new(xs.min, ys.min, xs.max - xs.min, ys.max - ys.min)
      end
    end

    def initialize(x:, y:, w:, h:)
      super(x: x, y: y, w: w, h: h)
    end

    def width = w
    def height = h
    def size = Vector.new(w, h)
    def area = w * h
    def empty? = w <= 0 || h <= 0

    def left = x
    def top = y
    def right = x + w
    def bottom = y + h
    def centerx = x + (w / 2.0)
    def centery = y + (h / 2.0)

    def position = Vector.new(x, y)
    alias topleft position
    def topright = Vector.new(right, y)
    def bottomleft = Vector.new(x, bottom)
    def bottomright = Vector.new(right, bottom)
    def center = Vector.new(centerx, centery)
    def midtop = Vector.new(centerx, y)
    def midbottom = Vector.new(centerx, bottom)
    def midleft = Vector.new(x, centery)
    def midright = Vector.new(right, centery)
    def corners = [topleft, topright, bottomright, bottomleft]

    def move(dx, dy = nil)
      delta = dy.nil? ? Vector.coerce(dx) : Vector.new(dx, dy)
      with(x: x + delta.x, y: y + delta.y)
    end

    def at(position) = with(x: Vector.coerce(position).x, y: Vector.coerce(position).y)
    def centered_at(point) = Rect.from_center(point, size)
    def resize(size) = with(w: Vector.coerce(size).x, h: Vector.coerce(size).y)

    # Grows (or shrinks, with negatives) around the centre.
    def inflate(dw, dh = dw)
      Rect.new(x - (dw / 2.0), y - (dh / 2.0), w + dw, h + dh)
    end

    def scale_by(factor_x, factor_y = factor_x)
      Rect.from_center(center, Vector.new(w * factor_x, h * factor_y))
    end

    # A rect with non-negative size covering the same area.
    def normalize
      nx, nw = w.negative? ? [x + w, -w] : [x, w]
      ny, nh = h.negative? ? [y + h, -h] : [y, h]
      Rect.new(nx, ny, nw, nh)
    end

    def contains?(thing)
      if thing.is_a?(Rect)
        thing.x >= x && thing.y >= y && thing.right <= right && thing.bottom <= bottom
      else
        p = Vector.coerce(thing)
        p.x >= x && p.x < right && p.y >= y && p.y < bottom
      end
    end
    alias include? contains?

    def collide?(other)
      other = Rect.coerce(other)
      x < other.right && other.x < right && y < other.bottom && other.y < bottom
    end
    alias intersect? collide?
    alias overlap? collide?

    # The overlapping area, or an empty rect at this rect's position.
    def clip(other)
      other = Rect.coerce(other)
      return Rect.new(x, y, 0, 0) unless collide?(other)

      nx = [x, other.x].max
      ny = [y, other.y].max
      Rect.new(nx, ny, [right, other.right].min - nx, [bottom, other.bottom].min - ny)
    end
    alias intersection clip

    def union(other)
      other = Rect.coerce(other)
      nx = [x, other.x].min
      ny = [y, other.y].min
      Rect.new(nx, ny, [right, other.right].max - nx, [bottom, other.bottom].max - ny)
    end

    # Moved the least distance needed to fit inside `other`.
    def clamp(other)
      other = Rect.coerce(other)
      nx = w >= other.w ? other.centerx - (w / 2.0) : x.clamp(other.x, other.right - w)
      ny = h >= other.h ? other.centery - (h / 2.0) : y.clamp(other.y, other.bottom - h)
      with(x: nx, y: ny)
    end

    def round = Rect.new(x.round, y.round, w.round, h.round)
    def to_a = [x, y, w, h]
    def to_s = "[#{x}, #{y}, #{w}x#{h}]"
  end
end
