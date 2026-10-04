# frozen_string_literal: true

module Gorillas
  # One building of the skyline. Immutable: a building is a value, and the
  # terrain holds the pixels that change.
  class Building < Data.define(:x, :width, :height, :color, :windows)
    # A window of a building, lit or dark.
    class Window < Data.define(:x, :y, :lit)
      WIDTH = 4
      HEIGHT = 7
      STEP_X = 10
      STEP_Y = 15
      MARGIN = 3
      LIT_CHANCE = 0.75

      # The windows of a building's face, in rows and columns, each lit by
      # the roll of the dice.
      def self.grid(rect, rng:)
        columns = (rect.x + MARGIN).step(rect.right - WIDTH - 2, STEP_X)
        rows = (rect.y + MARGIN).step(rect.bottom - HEIGHT - MARGIN, STEP_Y)
        columns.flat_map { |x| rows.map { |y| new(x: x, y: y, lit: rng.rand < LIT_CHANCE) } }.freeze
      end

      def rect = Rbgame::Rect.new(x, y, WIDTH, HEIGHT)
      def color = lit ? Palette::WINDOW_LIT : Palette::WINDOW_DARK
    end

    def self.build(x:, width:, height:, color:, rng:)
      rect = Rbgame::Rect.new(x, Field::STREET - height, width, height)
      new(x: x, width: width, height: height, color: color, windows: Window.grid(rect, rng: rng))
    end

    def top = Field::STREET - height
    def right = x + width
    def rect = Rbgame::Rect.new(x, top, width, height)
    def center_x = x + (width / 2.0)
    def roof = Rbgame::Vector.new(center_x, top)
    def spans?(point_x) = point_x >= x && point_x < right
  end
end
