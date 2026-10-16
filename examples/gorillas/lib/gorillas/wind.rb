# frozen_string_literal: true

module Gorillas
  # The wind: a strength from 0.0 (calm) to 9.9 in tenths, and a
  # direction, `speed` positive blowing to the right. It pushes a banana
  # sideways the whole time it is in the air, a steady acceleration that
  # grows with the square of the strength, so a 1.0 barely nudges a throw
  # and a 9.9 sweeps it across the city: a banana thrown straight up
  # drifts about 1.3 pixels in eight seconds at 1.0, 32 at 5.0 and 125
  # at 9.9, its sideways speed building by 0.04 * strength² pixels a
  # second every second.
  class Wind < Data.define(:speed)
    MAX = 9.9
    PUSH = 0.04 # acceleration per unit of strength squared

    def initialize(speed:)
      speed = Float(speed).round(1)
      raise ArgumentError, "wind strength runs 0.0 to #{MAX}, not #{speed.abs}" unless speed.abs <= MAX

      super
    end

    # A fresh roll, any strength in tenths either way; with `unlike:`,
    # rolled again until it differs from that wind, so every throw has a
    # wind of its own.
    def self.random(rng: Random.new, unlike: nil)
      loop do
        strength = rng.rand(0..(MAX * 10).round) / 10.0
        wind = new(speed: rng.rand(2).zero? ? -strength : strength)
        return wind unless wind == unlike
      end
    end

    def self.calm = new(speed: 0)

    # The sideways acceleration a banana feels, towards where it blows.
    def acceleration = PUSH * speed * strength
    def strength = speed.abs
    def calm? = speed.zero?
    def blowing_right? = speed.positive?
  end
end
