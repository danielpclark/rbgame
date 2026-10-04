# frozen_string_literal: true

require "test_helper"

class ShotTest < Minitest::Test
  Shot = Gorillas::Shot
  Wind = Gorillas::Wind

  def test_starts_at_its_origin
    shot = Shot.new(origin: [100, 200], angle: 45, velocity: 50)
    assert_equal Rbgame::Vector[100.0, 200.0], shot.position(0)
  end

  def test_gravity_pulls_down_and_the_arc_comes_back
    shot = Shot.new(origin: [0, 300], angle: 60, velocity: 40, gravity: 9.8)
    top = shot.position(3.5)
    assert_operator top.y, :<, 300, "the banana rises first (y grows downwards)"
    assert_operator shot.position(10).y, :>, top.y, "and falls again"
  end

  def test_direction_mirrors_the_throw
    right = Shot.new(origin: [320, 100], angle: 45, velocity: 50, direction: 1)
    left = Shot.new(origin: [320, 100], angle: 45, velocity: 50, direction: -1)
    assert_in_delta right.position(2).x - 320, 320 - left.position(2).x
    assert_in_delta right.position(2).y, left.position(2).y
  end

  def test_wind_pushes_sideways
    calm = Shot.new(origin: [0, 100], angle: 45, velocity: 50)
    gale = Shot.new(origin: [0, 100], angle: 45, velocity: 50, wind: Wind.new(speed: 10))
    assert_operator gale.position(4).x, :>, calm.position(4).x
    assert_in_delta gale.position(4).y, calm.position(4).y
    assert_in_delta 2.0, Wind.new(speed: 10).acceleration
  end

  def test_each_position_stops_when_the_banana_leaves_the_field
    shot = Shot.new(origin: [600, 100], angle: 10, velocity: 80)
    positions = shot.each_position.map { |pos, _t| pos }
    refute_empty positions
    assert positions.all? { |p| p.x <= Gorillas::Field::WIDTH && p.y <= Gorillas::Field::HEIGHT }
  end

  def test_wind_generation_is_within_the_originals_range
    rng = Random.new(1)
    speeds = Array.new(200) { Wind.random(rng: rng).speed }
    assert speeds.all? { |s| s.abs.between?(1, 20) }
    assert speeds.any?(&:negative?)
    assert speeds.any?(&:positive?)
  end
end
