# frozen_string_literal: true

module Gorillas
  module View
    # Names in the top corners, the score under the street.
    class Scoreboard
      MARGIN = 4 # from the field's edges to the names
      NAME_Y = 4

      def initialize(match)
        @match = match
      end

      def draw(canvas)
        text = Typography.new(canvas)
        text.line(@match.left.name, at: [MARGIN, NAME_Y])
        text.line(@match.right.name, at: [Field::WIDTH - MARGIN, NAME_Y], align: :right)
        text.line("#{@match.left.score}>Score<#{@match.right.score}", at: [Field::WIDTH / 2, Field::STREET + 1], align: :center)
      end
    end
  end
end
