# frozen_string_literal: true

module Gorillas
  # The playing field: EGA SCREEN 9, 640x350, with the street along the
  # bottom and the wind gauge below it, as in the original. On a 4:3
  # monitor those pixels were taller than wide, so the field is shown
  # stretched to 640x480 (WINDOW_SIZE) and shapes that should look round
  # are drawn squashed by ASPECT, as QBasic's CIRCLE drew them.
  module Field
    WIDTH = 640
    HEIGHT = 350
    SIZE = Rbgame::Vector.new(WIDTH, HEIGHT)
    WINDOW_SIZE = Rbgame::Vector.new(640, 480)
    ASPECT = HEIGHT.to_f / WIDTH * (4.0 / 3)
    BOUNDS = Rbgame::Rect.new(0, 0, WIDTH, HEIGHT)
    STREET = 335
    SUN_CENTER = Rbgame::Vector.new(WIDTH / 2, 25)

    def self.contains?(point) = BOUNDS.contains?(point)
    def self.left_half?(x) = x < WIDTH / 2
  end
end
