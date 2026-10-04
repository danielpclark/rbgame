# frozen_string_literal: true

module Gorillas
  # A circle of fire that grows to its full size, lingers a moment, and
  # leaves a crater that size.
  class Explosion
    GROWTH = 90.0 # pixels per second
    LINGER = 0.25
    BUILDING_RADIUS = 16
    GORILLA_RADIUS = 36

    attr_reader :center, :max_radius, :radius

    def initialize(center, max_radius: BUILDING_RADIUS)
      @center = Rbgame::Vector.coerce(center)
      @max_radius = max_radius
      @radius = 0.0
      @lingered = 0.0
    end

    def update(dt)
      if grown?
        @lingered += dt
      else
        @radius = [@radius + (GROWTH * dt), max_radius].min
      end
      self
    end

    def grown? = @radius >= max_radius
    def finished? = grown? && @lingered >= LINGER
    def crater_radius = max_radius
  end
end
