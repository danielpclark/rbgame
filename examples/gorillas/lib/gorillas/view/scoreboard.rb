# frozen_string_literal: true

module Gorillas
  module View
    # Names in the top corners, the score under the street.
    class Scoreboard
      def initialize(match)
        @match = match
      end

      def draw(canvas)
        text = Typography.new(canvas)
        text.line(@match.left.name, at: [4, 4])
        text.line(@match.right.name, at: [Field::WIDTH - 4, 4], align: :right)
        text.line("#{@match.left.score}>Score<#{@match.right.score}", at: [Field::WIDTH / 2, Field::STREET + 4], align: :center)
      end
    end
  end
end
