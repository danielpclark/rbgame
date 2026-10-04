# frozen_string_literal: true

module Gorillas
  # A throw, as pure physics: where is the banana `t` seconds in?
  #
  # These are GORILLA.BAS's equations:
  #   x = x0 + vx*t + (wind/5) * t^2 / 2
  #   y = y0 - vy*t + gravity * t^2 / 2
  # with angle in degrees from the horizontal, velocity in the game's own
  # units, and `direction` +1 for a gorilla throwing to the right.
  Shot = Data.define(:origin, :angle, :velocity, :direction, :gravity, :wind) do
    def initialize(origin:, angle:, velocity:, direction: 1, gravity: 9.8, wind: Wind.calm)
      super(origin: Rbgame::Vector.coerce(origin), angle: angle.to_f, velocity: velocity.to_f,
            direction: direction, gravity: gravity.to_f, wind: wind)
    end

    def radians = angle * Math::PI / 180
    def vx = Math.cos(radians) * velocity * direction
    def vy = Math.sin(radians) * velocity

    def position(t)
      x = origin.x + (vx * t) + (0.5 * wind.acceleration * t * t)
      y = origin.y - (vy * t) + (0.5 * gravity * t * t)
      Rbgame::Vector.new(x, y)
    end

    # Positions sampled every `step` seconds until the banana leaves the
    # field below or to the sides (it may fly above it, as in the original).
    def each_position(step: 0.1, max_time: 60)
      return enum_for(:each_position, step: step, max_time: max_time) unless block_given?

      t = 0.0
      while t <= max_time
        pos = position(t)
        break if pos.y > Field::HEIGHT || pos.x.negative? || pos.x > Field::WIDTH

        yield pos, t
        t += step
      end
    end
  end
end
