# frozen_string_literal: true

module Gorillas
  # Wind in GORILLA.BAS units: -10..10, positive blowing to the right, with
  # a one-in-three chance of a gust that doubles it.
  class Wind < Data.define(:speed)
    def self.random(rng: Random.new)
      speed = rng.rand(1..10)
      speed = -speed if rng.rand < 0.5
      speed *= 2 if rng.rand < 0.33
      new(speed: speed)
    end

    def self.calm = new(speed: 0)

    # The horizontal acceleration a banana feels, as the original computed it.
    def acceleration = speed / 5.0
    def calm? = speed.zero?
    def blowing_right? = speed.positive?
  end
end
