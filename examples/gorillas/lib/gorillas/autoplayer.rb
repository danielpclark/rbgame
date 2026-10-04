# frozen_string_literal: true

module Gorillas
  # A gorilla that aims for itself: it simulates candidate throws with the
  # same Shot physics the game uses, picks one that lands on the opponent,
  # then adds a human amount of error so rounds have some drama.
  class Autoplayer
    ANGLES = (15..80).step(5).to_a.freeze
    VELOCITIES = (25..100).step(5).to_a.freeze

    # An angle and a velocity, ready to be typed into the prompts.
    class Aim < Data.define(:angle, :velocity)
      def self.guess = new(angle: 45, velocity: 60)
      def to_answers = { angle: angle.round.to_s, velocity: velocity.round.to_s }
      def nudged(rng) = Aim.new(angle: (angle + rng.rand(-8..8)).clamp(5, 85), velocity: (velocity + rng.rand(-10..10)).clamp(10, 150))
    end

    # One candidate throw played out against the city.
    class Rehearsal
      attr_reader :aim, :miss

      def initialize(round, aim)
        @aim = aim
        @miss = play_out(round, round.shot_for(aim.angle, aim.velocity))
      end

      def hits? = !miss.nil? && miss < Gorilla::WIDTH / 2.0

      private

      # How close the banana passes to the target's centre when it reaches
      # the target; nil when something else gets in the way first.
      def play_out(round, shot)
        target = round.gorilla_of(round.target)
        home = round.thrower_gorilla.bounds.inflate(6)
        left_home = false
        shot.each_position(step: Flight::STEP) do |pos, _t|
          left_home ||= !home.contains?(pos)
          return pos.distance_to(target.center) if target.hit?(pos)
          return nil if left_home && round.terrain.solid?(pos)
        end
        nil
      end
    end

    attr_reader :accuracy

    # `accuracy` 1.0 always hits when a hit exists; 0.0 is wild guessing.
    def initialize(rng: Random.new, accuracy: 0.6)
      @rng = rng
      @accuracy = accuracy
    end

    def aim(round)
      best = best_shot(round) || Aim.guess
      @rng.rand < accuracy ? best : best.nudged(@rng)
    end

    # The cleanest hit among the candidates, or nil when none lands.
    def best_shot(round)
      ANGLES.product(VELOCITIES)
            .map { |angle, velocity| Rehearsal.new(round, Aim.new(angle: angle, velocity: velocity)) }
            .select(&:hits?)
            .min_by(&:miss)
            &.aim
    end
  end
end
