# frozen_string_literal: true

module Gorillas
  # A banana in the air: where it is now, how long it has flown, and
  # whether it has left its thrower's hands yet (it starts inside the
  # thrower, who is not a target for their own banana).
  class Flight
    STEP = 0.05 # simulated seconds between collision checks

    def self.off_field?(point) = point.y > Field::HEIGHT || point.x.negative? || point.x > Field::WIDTH

    attr_reader :shot, :time, :position

    def initialize(shot, thrower:)
      @shot = shot
      @home = thrower.bounds.inflate(6)
      @time = 0.0
      @position = shot.position(0)
      @left_home = false
    end

    # Moves `seconds` on in small steps, yielding after each one; the block
    # returns true to stop early (something was hit).
    def advance(seconds)
      steps = [(seconds / STEP).ceil, 1].max
      steps.times do
        step(seconds / steps)
        return self if block_given? && yield(self)
      end
      self
    end

    def banana = Banana.new(position: position, flight_time: time)
    def left_home? = @left_home
    def off_field? = Flight.off_field?(position)

    private

    def step(dt)
      @time += dt
      @position = shot.position(@time)
      @left_home ||= !@home.contains?(@position)
    end
  end
end
