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
    gale = Shot.new(origin: [0, 100], angle: 45, velocity: 50, wind: Wind.new(speed: 9))
    assert_operator gale.position(4).x, :>, calm.position(4).x
    assert_in_delta gale.position(4).y, calm.position(4).y
    assert_in_delta 0.04 * 81, Wind.new(speed: 9).acceleration
    assert_in_delta(-0.04 * 81, Wind.new(speed: -9).acceleration)
  end

  def test_wind_strength_runs_zero_to_nine_point_nine_in_tenths
    assert_equal 9.9, Wind.new(speed: -9.9).strength
    assert_equal 4.6, Wind.new(speed: 4.56).speed, "kept to one decimal place"
    assert_raises(ArgumentError) { Wind.new(speed: 10) }
    assert_raises(ArgumentError) { Wind.new(speed: -9.96) }
  end

  # Straight up there is no sideways throw: the banana starts with no
  # sideways movement at all, and every bit it gets is the wind's, added
  # second by second the whole flight long, so it goes faster and faster
  # the way the arrow points.
  def test_a_banana_thrown_straight_up_is_carried_ever_faster_by_the_wind
    assert drift(0).all?(&:zero?), "no wind, no drift"

    [1, 9.9, -1, -9.9, 0.1].each do |speed|
      assert_in_delta 0, sideways_speed(straight_up(speed), 0), 1e-9, "wind #{speed}: no sideways movement at first"
      speeds = Array.new(9) { |t| sideways_speed(straight_up(speed), t) }
      speeds.each_cons(2) do |before, after|
        assert_operator after * speed, :>, before * speed, "wind #{speed}: faster every second the arrow's way"
      end
    end
  end

  # Strength counts for far more than its number: 9.9 is not 9.9 times
  # 1.0 but 98, and carries a banana across a good part of the city.
  def test_a_strong_wind_has_a_humungous_effect
    assert_in_delta 9.9 * 9.9 * drift(1).last, drift(9.9).last, 1e-6
    assert_operator drift(1).last, :<, 10, "a strength of 1.0 barely nudges it"
    assert_in_delta 125, drift(9.9).last, 3, "a 9.9 carries it about 125 pixels in eight seconds"
    assert_in_delta 1.3, drift(1).last, 0.1, "and a 1.0 about 1.3"
    assert_operator drift(5.1).last, :>, drift(5).last, "and a tenth more is a little further"
  end

  # Thrown into the wind, the banana slows second by second, stops going
  # that way, then is blown back.
  def test_a_banana_thrown_into_the_wind_slows_and_turns_back
    shot = Shot.new(origin: [320, 300], angle: 60, velocity: 50, wind: Wind.new(speed: -9.9))
    speeds = Array.new(10) { |t| sideways_speed(shot, t) }
    assert_operator speeds.first, :>, 0, "thrown to the right"
    speeds.each_cons(2) { |before, after| assert_operator after, :<, before, "slower every second" }
    assert_operator speeds.last, :<, 0, "and blown back to the left"
  end

  # The same, through the Flight the game steps a banana with.
  def test_the_wind_acts_on_a_banana_in_the_air_throughout_its_flight
    thrower = Gorillas::Gorilla.new(feet: [320, 330])
    [2.5, -9.9].each do |speed|
      flight = Gorillas::Flight.new(straight_up(speed, origin: thrower.hand), thrower: thrower)
      xs = [flight.position.x]
      8.times { xs << flight.advance(1.0).position.x }
      steps = xs.each_cons(2).map { |a, b| b - a }
      assert steps.all? { |dx| (dx * speed).positive? }, "wind #{speed}: it drifts the wind's way"
      steps.each_cons(2) { |before, after| assert_operator after.abs, :>, before.abs, "wind #{speed}: ever faster" }
    end
  end

  def test_each_position_stops_when_the_banana_leaves_the_field
    shot = Shot.new(origin: [600, 100], angle: 10, velocity: 80)
    positions = shot.each_position.map { |pos, _t| pos }
    refute_empty positions
    assert positions.all? { |p| p.x <= Gorillas::Field::WIDTH && p.y <= Gorillas::Field::HEIGHT }
  end

  def test_wind_generation_covers_zero_to_nine_point_nine_in_tenths
    rng = Random.new(1)
    speeds = Array.new(2000) { Wind.random(rng: rng).speed }
    assert speeds.all? { |s| s.between?(-9.9, 9.9) }
    assert speeds.all? { |s| (s * 10).round(6) == (s * 10).round }, "in tenths"
    assert speeds.any? { |s| s != s.round }, "with decimals"
    assert speeds.any?(&:negative?)
    assert speeds.any?(&:positive?)
    assert speeds.any?(&:zero?), "a calm day comes round"
    assert speeds.any? { |s| s.abs == 9.9 }, "and so does the strongest gale"
  end

  private

  def straight_up(speed, origin: [320, 300])
    Shot.new(origin: origin, angle: 90, velocity: 50, wind: Wind.new(speed: speed))
  end

  # How far a straight-up banana has been blown sideways, second by second.
  def drift(speed) = Array.new(9) { |t| straight_up(speed).position(t).x - 320 }

  # Pixels per second sideways at `t`, from the positions either side.
  def sideways_speed(shot, t, dt = 1e-3) = (shot.position(t + dt).x - shot.position(t - dt).x) / (2 * dt)
end
