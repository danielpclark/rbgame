# frozen_string_literal: true

module Rbgame
  # An immutable 2D vector; also the type rbgame uses for points and sizes.
  #
  #   v = Vector.new(3, 4)
  #   v.magnitude            # => 5.0
  #   v + Vector[1, 1]       # => Vector[4, 5]
  #   v * 2                  # => Vector[6, 8]
  #   Vector.polar(90, 10)   # 10 units straight up (angles in degrees, y down)
  Vector = Data.define(:x, :y) do
    class << self
      remove_method :[] # Data's own `[]` is `new`; ours coerces

      # Vector[1, 2], Vector[[1, 2]], Vector[other_vector]
      def [](*args)
        coerce(args.length == 1 ? args.first : args)
      end

      def coerce(value)
        case value
        when Vector then value
        when Array then new(*value)
        when Hash then new(**value)
        else
          if value.respond_to?(:x) && value.respond_to?(:y)
            new(value.x, value.y)
          else
            raise TypeError, "cannot convert #{value.class} to #{name}"
          end
        end
      end

      # A vector of `length` pointing `degrees` counter-clockwise from the
      # positive x axis, in screen coordinates (y grows downwards).
      def polar(degrees, length = 1.0)
        radians = degrees * Math::PI / 180
        new(Math.cos(radians) * length, -Math.sin(radians) * length)
      end

      def zero = new(0, 0)
    end

    def +(other)
      other = Vector.coerce(other)
      Vector.new(x + other.x, y + other.y)
    end

    def -(other)
      other = Vector.coerce(other)
      Vector.new(x - other.x, y - other.y)
    end

    def *(scalar)
      scalar.is_a?(Numeric) ? Vector.new(x * scalar, y * scalar) : scale(scalar)
    end

    def /(scalar) = Vector.new(x / scalar.to_f, y / scalar.to_f)
    def -@ = Vector.new(-x, -y)
    def +@ = self

    # Lets `2 * vector` work.
    def coerce(scalar) = [self, scalar]

    # Component-wise multiplication.
    def scale(other)
      other = Vector.coerce(other)
      Vector.new(x * other.x, y * other.y)
    end

    def dot(other)
      other = Vector.coerce(other)
      (x * other.x) + (y * other.y)
    end

    def magnitude = Math.sqrt((x * x) + (y * y))
    alias length magnitude
    def magnitude_squared = (x * x) + (y * y)
    def zero? = x.zero? && y.zero?

    def normalize
      m = magnitude
      m.zero? ? self : self / m
    end

    def distance_to(other) = (self - other).magnitude

    # Degrees counter-clockwise from the positive x axis, in screen
    # coordinates (so Vector[0, -1].angle is 90).
    def angle = Math.atan2(-y, x) * 180 / Math::PI

    def rotate(degrees)
      radians = degrees * Math::PI / 180
      cos, sin = Math.cos(radians), Math.sin(radians)
      Vector.new((x * cos) + (y * sin), (y * cos) - (x * sin))
    end

    def lerp(other, t)
      other = Vector.coerce(other)
      self + ((other - self) * t)
    end

    def round = Vector.new(x.round, y.round)
    def floor = Vector.new(x.floor, y.floor)
    def to_a = [x, y]
    def to_i = round
    def to_s = "(#{x}, #{y})"
  end

  class Vector
    ZERO = Vector.new(0, 0)
  end
end
