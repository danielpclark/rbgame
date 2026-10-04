# frozen_string_literal: true

require "test_helper"

class RoundTest < Minitest::Test
  Round = Gorillas::Round

  def setup
    GorillasTest.init!
    @match = GorillasTest.match(seed: 11, play_to: 2)
    @round = @match.new_round
  end

  def run_until(round, seconds: 60, dt: 1 / 30.0)
    (seconds / dt).to_i.times do
      round.update(dt)
      return round if yield(round)
    end
    flunk "round never reached the expected phase (#{round.phase})"
  end

  def test_setup
    assert @round.aiming?
    assert_equal @match.left, @round.thrower
    assert_equal :right, @round.gorilla_of(@match.left).facing
    left, right = @round.gorilla_of(@match.left), @round.gorilla_of(@match.right)
    assert_operator left.feet.x, :<, right.feet.x
    assert_equal @round.skyline.building_under(left.feet.x).top, left.feet.y
  end

  def test_a_miss_passes_the_turn
    @round.throw(80, 10) # straight up, barely; lands on the thrower's own building or the street
    run_until(@round) { |r| r.aiming? }
    assert_equal @match.right, @round.thrower
    assert_equal 0, @match.total_points
  end

  def test_a_direct_hit_scores_and_ends_the_round
    aim = Gorillas::Autoplayer.new(rng: Random.new(1), accuracy: 1.0).best_shot(@round)
    skip "no clean shot on this city" unless aim

    @round.throw(aim.angle, aim.velocity)
    run_until(@round) { |r| r.over? }
    assert @round.outcome.hit_gorilla?
    assert_equal @match.right, @round.outcome.victim
    assert_equal 1, @match.left.score
    assert_equal @match.left, @round.winner
    refute @match.over?
  end

  def test_throwing_out_of_turn_raises
    @round.throw(45, 50)
    assert_raises(Rbgame::StateError) { @round.throw(45, 50) }
  end

  def test_the_thrower_never_hits_itself_on_the_way_out
    @round.throw(90, 30)
    run_until(@round) { |r| !r.flying? }
    refute @round.outcome.hit_gorilla?
  end
end
