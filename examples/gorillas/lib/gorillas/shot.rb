# frozen_string_literal: true

module Gorillas
  # A throw as pure physics: where is the banana `t` seconds in?
  #
  # These are GORILLA.BAS's equations, with angle in degrees from the
  # horizontal, velocity in the game's own units and `direction` +1 for a
  # throw to the right:
  #   x = x0 + vx*t + (wind/5) * t^2 / 2
  #   y = y0 - vy*t + gravity * t^2 / 2
  class Shot < Data.define(:origin, :angle, :velocity, :direction, :gravity, :wind)
    def initialize(origin:, angle:, velocity:, direction: 1, gravity: 9.8, wind: Wind.calm)
      super(origin: Rbgame::Vector.coerce(origin), angle: angle.to_f, velocity: velocity.to_f,
            direction: direction, gravity: gravity.to_f, wind: wind)
    end

    def radians = angle * Math::PI / 180
    def vx = Math.cos(radians) * velocity * direction
    def vy = Math.sin(radians) * velocity

    def position(t)
      Rbgame::Vector.new(
        origin.x + (vx * t) + (0.5 * wind.acceleration * t * t),
        origin.y - (vy * t) + (0.5 * gravity * t * t)
      )
    end

    # Positions sampled every `step` seconds until the banana leaves the
    # field below or to the sides (it may fly above it, as in the original).
    def each_position(step: 0.1, max_time: 60)
      return enum_for(:each_position, step: step, max_time: max_time) unless block_given?

      0.0.step(max_time, step) do |t|
        pos = position(t)
        break if Flight.off_field?(pos)

        yield pos, t
      end
    end
  end
end
