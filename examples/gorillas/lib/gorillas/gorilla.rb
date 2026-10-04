# frozen_string_literal: true

module Gorillas
  # A gorilla standing on a roof: where its feet are, which way it faces,
  # and which arms are up. Poses are new gorillas, not mutations.
  class Gorilla < Data.define(:feet, :facing, :pose)
    WIDTH = 28
    HEIGHT = 30
    POSES = %i[at_ease left_up right_up both_up].freeze

    def initialize(feet:, facing: :right, pose: :at_ease)
      raise ArgumentError, "unknown pose #{pose.inspect}" unless POSES.include?(pose)

      super(feet: Rbgame::Vector.coerce(feet), facing: facing, pose: pose)
    end

    def bounds = Rbgame::Rect.new(feet.x - (WIDTH / 2), feet.y - HEIGHT, WIDTH, HEIGHT)
    def center = bounds.center
    def hit?(point) = bounds.contains?(point)
    def facing_right? = facing == :right

    # Where a throw leaves the hand.
    def hand
      x = facing_right? ? bounds.right + 2 : bounds.left - 2
      Rbgame::Vector.new(x, bounds.top - 4)
    end

    def throwing = with(pose: facing_right? ? :right_up : :left_up)
    def at_ease = with(pose: :at_ease)
    def arm_up?(side) = pose == :both_up || pose == :"#{side}_up"

    # The victory dance: arms alternate on every beat.
    def dancing(beat) = with(pose: beat.even? ? :left_up : :right_up)
  end
end
