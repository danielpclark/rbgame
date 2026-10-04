# frozen_string_literal: true

module Gorillas
  module View
    # Draws a Gorilla as DrawGorilla did: boxes and circles, arms by pose.
    class GorillaSprite
      ARM_WIDTH = 4

      def initialize(gorilla)
        @gorilla = gorilla
      end

      def draw(canvas)
        b = @gorilla.bounds
        body = Palette::GORILLA
        detail = Palette::GORILLA_DETAIL

        canvas.fill_rect([b.x + 7, b.y, 14, 8], body)                 # head
        canvas.fill_rect([b.x + 8, b.y + 2, 3, 2], detail)            # eyes
        canvas.fill_rect([b.x + 17, b.y + 2, 3, 2], detail)
        canvas.line([b.x + 9, b.y + 6], [b.x + 19, b.y + 6], detail)  # mouth
        canvas.fill_rect([b.x + 10, b.y + 8, 8, 2], body)             # neck
        canvas.fill_rect([b.x + 4, b.y + 10, 20, 12], body)           # chest
        canvas.line([b.x + 14, b.y + 12], [b.x + 14, b.y + 20], detail)
        canvas.circle([b.x + 8, b.y + 24], 6, body)                   # legs
        canvas.circle([b.x + 20, b.y + 24], 6, body)
        canvas.fill_rect([b.x + 4, b.y + 24, 20, 6], body)
        arm(canvas, :left, Rbgame::Vector.new(b.x + 4, b.y + 12), body)
        arm(canvas, :right, Rbgame::Vector.new(b.x + 24, b.y + 12), body)
      end

      private

      def arm(canvas, side, shoulder, color)
        up = @gorilla.arm_up?(side)
        outward = side == :left ? -1 : 1
        elbow = shoulder + Rbgame::Vector.new(4 * outward, up ? -6 : 7)
        hand = up ? elbow + Rbgame::Vector.new(0, -8) : elbow + Rbgame::Vector.new(2 * outward, 5)
        canvas.line(shoulder, elbow, color, width: ARM_WIDTH)
        canvas.line(elbow, hand, color, width: ARM_WIDTH)
      end
    end
  end
end
