# frozen_string_literal: true

module Gorillas
  # A gorilla that aims for itself: it simulates candidate throws with the
  # same Shot physics the game uses, picks one that lands on the opponent,
  # then adds a human amount of error so rounds have some drama.
  class Autoplayer
    ANGLES = (15..80).step(5).to_a.freeze
    VELOCITIES = (25..100).step(5).to_a.freeze

    Aim = Data.define(:angle, :velocity)

    attr_reader :accuracy

    # `accuracy` 1.0 always hits when a hit exists; 0.0 is wild guessing.
    def initialize(rng: Random.new, accuracy: 0.6)
      @rng = rng
      @accuracy = accuracy
    end

    def aim(round)
      best = best_shot(round) || Aim.new(angle: 45, velocity: 60)
      return best if @rng.rand < accuracy

      Aim.new(angle: (best.angle + @rng.rand(-8..8)).clamp(5, 85),
              velocity: (best.velocity + @rng.rand(-10..10)).clamp(10, 150))
    end

    # The cleanest hit among the candidates: the one passing nearest the
    # opponent's centre before touching anything else.
    def best_shot(round)
      target = round.gorilla_of(round.target)
      own = round.thrower_gorilla.bounds.inflate(6)
      candidates = ANGLES.product(VELOCITIES).filter_map do |angle, velocity|
        miss = closest_approach(round, round.shot_for(angle, velocity), target, own)
        [miss, Aim.new(angle: angle, velocity: velocity)] if miss
      end
      hit = candidates.min_by(&:first)
      hit && hit.first < Gorilla::WIDTH / 2.0 ? hit.last : nil
    end

    private

    def closest_approach(round, shot, target, own_bounds)
      closest = Float::INFINITY
      left_own = false
      shot.each_position(step: 0.05) do |pos, _t|
        left_own ||= !own_bounds.contains?(pos)
        return pos.distance_to(target.center) if target.hit?(pos)
        return nil if left_own && round.terrain.solid?(pos)

        closest = [closest, pos.distance_to(target.center)].min
      end
      nil
    end
  end
end
