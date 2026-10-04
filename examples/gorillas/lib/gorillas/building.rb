# frozen_string_literal: true

module Gorillas
  # One building of the skyline, with its lit and dark windows.
  class Building < Data.define(:x, :width, :height, :color, :windows)
    WINDOW_WIDTH = 4
    WINDOW_HEIGHT = 7
    WINDOW_STEP_X = 10
    WINDOW_STEP_Y = 15

    def top = Field::STREET - height
    def right = x + width
    def rect = Rbgame::Rect.new(x, top, width, height)
    def center_x = x + (width / 2.0)
    def roof = Rbgame::Vector.new(center_x, top)

    # Window rectangles with their colours, laid out as MakeCityScape did.
    def window_rects
      windows.map { |(wx, wy, lit)| [Rbgame::Rect.new(wx, wy, WINDOW_WIDTH, WINDOW_HEIGHT), lit] }
    end

    class << self
      # Lays out the windows for a building and rolls which are lit.
      def build(x:, width:, height:, color:, rng:)
        top = Field::STREET - height
        windows = []
        (x + 3).step(x + width - WINDOW_WIDTH - 2, WINDOW_STEP_X) do |wx|
          (top + 3).step(Field::STREET - WINDOW_HEIGHT - 3, WINDOW_STEP_Y) do |wy|
            windows << [wx, wy, rng.rand < 0.75]
          end
        end
        new(x: x, width: width, height: height, color: color, windows: windows.freeze)
      end
    end
  end
end
