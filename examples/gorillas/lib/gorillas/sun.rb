# frozen_string_literal: true

module Gorillas
  # The sun at the top of the field. It smiles, unless a banana just went
  # through it, in which case it is as shocked as you would be.
  class Sun < Data.define(:center, :shocked)
    RADIUS = 12
    RAY = 20

    def initialize(center: Field::SUN_CENTER, shocked: false)
      super(center: Rbgame::Vector.coerce(center), shocked: shocked)
    end

    def shocked? = shocked
    def hit?(point) = center.distance_to(point) <= RADIUS + 2
    def shock = with(shocked: true)
    def calm = with(shocked: false)

    def draw(canvas)
      8.times do |i|
        canvas.line(center, center + Rbgame::Vector.polar(i * 45, RAY), Palette::SUN)
      end
      canvas.circle(center, RADIUS, Palette::SUN)
      canvas.circle(center + Rbgame::Vector.new(-4, -3), 1.5, Palette::FACE)
      canvas.circle(center + Rbgame::Vector.new(4, -3), 1.5, Palette::FACE)
      if shocked?
        canvas.circle(center + Rbgame::Vector.new(0, 4), 3, Palette::FACE)
      else
        canvas.arc(center + Rbgame::Vector.new(0, 1), 6, 200, 340, Palette::FACE)
      end
    end
  end
end
