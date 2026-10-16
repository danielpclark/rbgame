# frozen_string_literal: true

module Gorillas
  module View
    # A Gorilla drawn as DrawGorilla drew it: boxes for the head and body,
    # a line for the brow, dots for the nose, arcs for the legs, the chest
    # and the arms, each arc five pixels thick. `x` and `y` are the
    # original's: the head's centre line and the top of the head.
    class GorillaSprite
      # Where each arm's arc is centred, by pose: up is at y + 4, down at
      # y + 14, as the original's three poses had them.
      ARMS = { at_ease: [14, 14], left_up: [4, 14], right_up: [14, 4], both_up: [4, 4] }.freeze

      def initialize(gorilla)
        @gorilla = gorilla
      end

      def draw(canvas)
        bounds = @gorilla.bounds
        x = bounds.x + 15
        y = bounds.y + 1
        body = Palette::GORILLA
        black = Palette::GORILLA_DETAIL

        # Head
        Ega.box(canvas, x - 4, y, x + 2, y + 6, body)
        Ega.box(canvas, x - 5, y + 2, x + 3, y + 4, body)
        # Eyes and brow
        Ega.line(canvas, x - 3, y + 2, x + 1, y + 2, black)
        # Nose
        [-2, -1].each do |i|
          Ega.pset(canvas, x + i, y + 4, black)
          Ega.pset(canvas, x + i + 3, y + 4, black)
        end
        # Neck
        Ega.line(canvas, x - 3, y + 7, x + 2, y + 7, body)
        # Body
        Ega.box(canvas, x - 8, y + 8, x + 6, y + 14, body)
        Ega.box(canvas, x - 6, y + 15, x + 4, y + 20, body)
        # Legs
        Ega.arc(canvas, [x, y + 25], 10, 135, 202.5, body, thickness: 5)
        Ega.arc(canvas, [x - 6.1, y + 25], 10, 337.5, 45, body, thickness: 5)
        # Chest
        Ega.arc(canvas, [x - 5, y + 10], 4.9, 270, 360, black)
        Ega.arc(canvas, [x + 4, y + 10], 4.9, 180, 270, black)
        # Arms
        left, right = ARMS.fetch(@gorilla.pose)
        Ega.arc(canvas, [x - 5, y + left], 9, 135, 225, body, thickness: 5)
        Ega.arc(canvas, [x - 0.1, y + right], 9, 315, 45, body, thickness: 5)
      end
    end
  end
end
