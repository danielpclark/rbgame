# frozen_string_literal: true

require "test_helper"

# The small value objects of the field.
class ModelTest < Minitest::Test
  def test_gorilla_poses_are_new_gorillas
    gorilla = Gorillas::Gorilla.new(feet: [100, 300], facing: :right)
    assert_equal :at_ease, gorilla.pose
    assert_equal :right_up, gorilla.throwing.pose
    assert_equal :left_up, gorilla.with(facing: :left).throwing.pose
    assert_equal :at_ease, gorilla.pose, "the original is untouched"
    assert gorilla.throwing.arm_up?(:right)
    refute gorilla.throwing.arm_up?(:left)
    assert_equal %i[left_up right_up], [gorilla.dancing(0).pose, gorilla.dancing(1).pose]
    assert_operator gorilla.hand.x, :>, gorilla.bounds.right
    assert_raises(ArgumentError) { Gorillas::Gorilla.new(feet: [0, 0], pose: :headstand) }
  end

  def test_banana_tumbles_through_four_frames
    frames = (0..1).step(1.0 / 6).map { |t| Gorillas::Banana.new(position: [0, 0], flight_time: t).frame }
    assert_equal [0, 1, 2, 3, 0, 1, 2], frames
    assert_equal 90, Gorillas::Banana.new(position: [0, 0], flight_time: 1.0 / 6).rotation
  end

  def test_sun_shock_wears_off
    sun = Gorillas::Sun.new.startled
    assert sun.shocked?
    assert sun.after(1.0).shocked?
    refute sun.after(Gorillas::Sun::SHOCK_SECONDS).shocked?
    assert sun.hit?(sun.center + [Gorillas::Sun::RADIUS, 0])
    refute sun.hit?(sun.center + [100, 0])
  end

  def test_explosion_grows_then_finishes
    explosion = Gorillas::Explosion.new([10, 10], max_radius: 9)
    explosion.update(0.05)
    assert_in_delta 4.5, explosion.radius
    refute explosion.grown?
    explosion.update(1.0)
    assert explosion.grown?
    refute explosion.finished?
    explosion.update(Gorillas::Explosion::LINGER)
    assert explosion.finished?
    assert_equal 9, explosion.crater_radius
  end

  def test_outcomes
    victim = Object.new
    assert Gorillas::Outcome.gorilla([1, 2], victim).hit_gorilla?
    assert_equal Gorillas::Explosion::GORILLA_RADIUS, Gorillas::Outcome.gorilla([1, 2], victim).explosion_radius
    assert Gorillas::Outcome.building([1, 2]).hit_building?
    assert Gorillas::Outcome.missed([1, 2]).missed?
  end

  def test_jukebox_is_a_round_listener
    silent = Gorillas::Jukebox.for(false)
    refute silent.call(:explosion)
    jukebox = Gorillas::Jukebox.for(true)
    refute jukebox.call(:nothing_to_play)
    assert_equal 5, Gorillas::Jukebox::TUNES.length
  end
end
