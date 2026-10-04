# frozen_string_literal: true

module Gorillas
  # A growing circle of fire that leaves a crater its own size. It is a
  # plain object with time in it, advanced by Round.
  class Explosion
    GROWTH = 90.0 # pixels per second
    BUILDING_RADIUS = 16
    GORILLA_RADIUS = 36

    attr_reader :center, :max_radius, :radius

    def initialize(center, max_radius: BUILDING_RADIUS)
      @center = Rbgame::Vector.coerce(center)
      @max_radius = max_radius
      @radius = 0.0
      @fade = 0.0
    end

    def update(dt)
      if @radius < max_radius
        @radius = [@radius + (GROWTH * dt), max_radius].min
      else
        @fade += dt
      end
      self
    end

    def grown? = @radius >= max_radius
    def finished? = grown? && @fade >= 0.25

    def draw(canvas)
      canvas.circle(center, radius, Palette::EXPLOSION)
      canvas.circle(center, radius * 0.5, Palette::EXPLOSION_CORE) if radius > 4
    end
  end
end
