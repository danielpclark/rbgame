# frozen_string_literal: true

module Gorillas
  # The playing field: EGA SCREEN 9, 640x350, with the street along the
  # bottom and the wind gauge below it, as in the original.
  module Field
    WIDTH = 640
    HEIGHT = 350
    SIZE = Rbgame::Vector.new(WIDTH, HEIGHT)
    BOUNDS = Rbgame::Rect.new(0, 0, WIDTH, HEIGHT)
    STREET = 335
    SUN_CENTER = Rbgame::Vector.new(WIDTH / 2, 25)

    def self.contains?(point) = BOUNDS.contains?(point)
    def self.left_half?(x) = x < WIDTH / 2
  end
end
