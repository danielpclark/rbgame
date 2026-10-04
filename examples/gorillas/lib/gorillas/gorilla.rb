# frozen_string_literal: true

module Gorillas
  # A gorilla standing on a roof. `feet` is the point between its feet;
  # `pose` is which arms are up (:down, :left_up, :right_up, :both_up).
  class Gorilla < Data.define(:feet, :pose, :facing)
    WIDTH = 28
    HEIGHT = 30

    def initialize(feet:, pose: :down, facing: :right)
      super(feet: Rbgame::Vector.coerce(feet), pose: pose, facing: facing)
    end

    def bounds = Rbgame::Rect.new(feet.x - (WIDTH / 2), feet.y - HEIGHT, WIDTH, HEIGHT)
    def hit?(point) = bounds.contains?(point)
    def center = bounds.center

    # Where a throw leaves the hand.
    def hand
      x = facing == :right ? bounds.right + 2 : bounds.left - 2
      Rbgame::Vector.new(x, bounds.top - 4)
    end

    def throwing_pose = facing == :right ? :right_up : :left_up

    def draw(canvas)
      b = bounds
      body = Palette::GORILLA
      detail = Palette::GORILLA_DETAIL

      # head
      canvas.fill_rect([b.x + 7, b.y, 14, 8], body)
      canvas.fill_rect([b.x + 8, b.y + 2, 3, 2], detail)
      canvas.fill_rect([b.x + 17, b.y + 2, 3, 2], detail)
      canvas.line([b.x + 9, b.y + 6], [b.x + 19, b.y + 6], detail)
      # neck and chest
      canvas.fill_rect([b.x + 10, b.y + 8, 8, 2], body)
      canvas.fill_rect([b.x + 4, b.y + 10, 20, 12], body)
      canvas.line([b.x + 14, b.y + 12], [b.x + 14, b.y + 20], detail)
      # legs
      canvas.circle([b.x + 8, b.y + 24], 6, body)
      canvas.circle([b.x + 20, b.y + 24], 6, body)
      canvas.fill_rect([b.x + 4, b.y + 24, 20, 6], body)
      # arms
      draw_arm(canvas, Rbgame::Vector.new(b.x + 4, b.y + 12), :left, body)
      draw_arm(canvas, Rbgame::Vector.new(b.x + 24, b.y + 12), :right, body)
    end

    private

    def draw_arm(canvas, shoulder, side, color)
      up = pose == :both_up || pose == :"#{side}_up"
      sideways = side == :left ? -1 : 1
      elbow = shoulder + Rbgame::Vector.new(4 * sideways, up ? -6 : 7)
      hand = up ? elbow + Rbgame::Vector.new(0, -8) : elbow + Rbgame::Vector.new(2 * sideways, 5)
      canvas.line(shoulder, elbow, color, width: 4)
      canvas.line(elbow, hand, color, width: 4)
    end
  end
end
