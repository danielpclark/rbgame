# frozen_string_literal: true

module Gorillas
  # The projectile at an instant: where it is and how it is turned. It
  # tumbles through four orientations as it flies, as DrawBan cycled its
  # four shapes.
  class Banana < Data.define(:position, :flight_time)
    FRAMES = 4
    TUMBLE_RATE = 6 # frames per simulated second

    def initialize(position:, flight_time: 0.0)
      super(position: Rbgame::Vector.coerce(position), flight_time: flight_time)
    end

    def frame = (flight_time * TUMBLE_RATE).floor % FRAMES
    def rotation = frame * 90
  end
end
