# frozen_string_literal: true

require "test_helper"

class RoundTest < Minitest::Test
  def setup
    GorillasTest.init!
    @match = GorillasTest.match(seed: 11, play_to: 2)
    @heard = []
    @round = @match.new_round(listener: ->(event) { @heard << event })
  end

  def run_until(...) = GorillasTest.run_until(...)

  def test_setup
    assert @round.aiming?
    assert_equal @match.left, @round.thrower
    left, right = @round.gorilla_of(@match.left), @round.gorilla_of(@match.right)
    assert_equal :right, left.facing
    assert_operator left.feet.x, :<, right.feet.x
    assert_equal @round.skyline.building_under(left.feet.x).top, left.feet.y
    assert_nil @round.banana
    assert_nil @round.explosion
  end

  def test_a_miss_passes_the_turn
    @round.throw(80, 10)
    assert @round.flying?
    assert_equal :right_up, @round.thrower_gorilla.pose
    run_until(@round) { |r| r.aiming? }
    assert_equal @match.right, @round.thrower
    assert @round.gorillas.all? { |g| g.pose == :at_ease }
    assert_equal 0, @match.total_points
  end

  def test_a_direct_hit_explodes_scores_and_dances
    aim = nil
    (1..12).each do |seed|
      @match = GorillasTest.match(seed: seed, play_to: 2)
      @round = @match.new_round(listener: ->(event) { @heard << event })
      aim = Gorillas::Autoplayer.new(rng: Random.new(1), accuracy: 1.0).best_shot(@round)
      break if aim
    end
    skip "no clean shot on any of these cities" unless aim

    @round.throw(aim.angle, aim.velocity)
    run_until(@round) { |r| r.exploding? }
    assert_includes @heard, :gorilla_hit
    assert @round.explosion
    run_until(@round) { |r| r.dancing? }
    assert_includes @heard, :victory
    assert_equal 1, @match.left.score
    run_until(@round) { |r| r.over? }
    assert @round.outcome.hit_gorilla?
    assert_equal @match.right, @round.outcome.victim
    assert_equal @match.left, @round.winner
    refute @match.over?
  end

  def test_a_building_hit_leaves_a_crater_and_passes_the_turn
    @round.throw(10, 40)
    run_until(@round) { |r| r.exploding? }
    assert_includes @heard, :explosion
    point = @round.outcome.point
    assert @round.terrain.solid?(point)
    run_until(@round) { |r| r.aiming? }
    refute @round.terrain.solid?(point), "the crater removed the terrain"
    assert_equal @match.right, @round.thrower
  end

  def test_the_sun_is_startled_and_recovers
    angle, velocity = shot_through_the_sun
    skip "no throw reaches the sun on this city" unless angle

    @round.throw(angle, velocity)
    run_until(@round) { |r| r.sun.shocked? }
    assert_includes @heard, :sun_hit
    run_until(@round) { |r| r.aiming? && !r.sun.shocked? }
  end

  # An angle and velocity whose arc crosses the sun before anything else.
  def shot_through_the_sun
    (40..85).step(5).each do |angle|
      (40..120).step(5).each do |velocity|
        shot = @round.shot_for(angle, velocity)
        shot.each_position(step: 0.05) do |pos, _t|
          return [angle, velocity] if @round.sun.hit?(pos)
          break if @round.terrain.solid?(pos)
        end
      end
    end
    nil
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
