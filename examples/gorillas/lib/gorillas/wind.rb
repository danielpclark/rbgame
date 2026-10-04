# frozen_string_literal: true

module Gorillas
  # Wind, in GORILLA.BAS units: -10 .. 10, positive blowing to the right,
  # with a one-in-three chance of a gust that doubles it.
  Wind = Data.define(:speed) do
    def self.random(rng: Random.new)
      speed = rng.rand(1..10)
      speed = -speed if rng.rand < 0.5
      speed *= 2 if rng.rand < 0.33
      new(speed: speed)
    end

    def self.calm = new(speed: 0)

    # Horizontal acceleration the banana feels, as the original computed it.
    def acceleration = speed / 5.0
    def calm? = speed.zero?
    def blowing_right? = speed.positive?

    # The gauge: an arrow along the bottom of the field.
    def draw(canvas)
      return if calm?

      y = Field::STREET + 10
      from = Rbgame::Vector.new(Field::WIDTH / 2, y)
      to = from + Rbgame::Vector.new(speed * 3, 0)
      canvas.line(from, to, Palette::WIND)
      head = blowing_right? ? -2 : 2
      canvas.line(to, to + Rbgame::Vector.new(head, -2), Palette::WIND)
      canvas.line(to, to + Rbgame::Vector.new(head, 2), Palette::WIND)
    end
  end
end
