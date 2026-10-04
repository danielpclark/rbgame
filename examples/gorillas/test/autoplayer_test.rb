# frozen_string_literal: true

require "test_helper"

class AutoplayerTest < Minitest::Test
  def setup
    GorillasTest.init!
  end

  def test_finds_a_hit_on_some_city
    hits = (1..6).count do |seed|
      round = GorillasTest.match(seed: seed).new_round
      !Gorillas::Autoplayer.new(rng: Random.new(seed), accuracy: 1.0).best_shot(round).nil?
    end
    assert_operator hits, :>=, 3, "the autoplayer should find clean shots on most cities"
  end

  def test_perfect_accuracy_returns_the_best_shot
    round = GorillasTest.match(seed: 1).new_round
    player = Gorillas::Autoplayer.new(rng: Random.new(1), accuracy: 1.0)
    assert_equal player.best_shot(round) || Gorillas::Autoplayer::Aim.new(angle: 45, velocity: 60), player.aim(round)
  end

  def test_aims_stay_sane
    round = GorillasTest.match(seed: 2).new_round
    player = Gorillas::Autoplayer.new(rng: Random.new(2), accuracy: 0.0)
    20.times do
      aim = player.aim(round)
      assert_includes 5..85, aim.angle
      assert_includes 10..150, aim.velocity
    end
  end
end
