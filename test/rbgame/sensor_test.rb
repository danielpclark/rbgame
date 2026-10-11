# frozen_string_literal: true

require "test_helper"

# The machine's own sensors. Linux has no SDL sensor driver but the dummy
# one, so this exercises the empty case and the value objects; the gamepad
# tests drive real readings through a virtual pad's sensors.
class SensorTest < Minitest::Test
  Sensor = Rbgame::Sensor
  Reading = Sensor::Reading

  def test_lists_what_the_platform_has
    sensors = Sensor.all
    assert_kind_of Array, sensors
    sensors.each do |sensor|
      assert_kind_of Integer, sensor.id
      assert_includes Sensor::TYPES, sensor.type
      assert_equal 3, sensor.reading.to_a.size
      assert_same sensor, Sensor.find(sensor.id)
    end
    assert_equal sensors.any?, Sensor.any?
    assert_equal sensors.count(&:accelerometer?), Sensor.accelerometers.size
  end

  def test_none_stands_in_when_there_is_no_sensor
    none = Sensor.find(0)
    assert none.none?
    assert_equal :none, none.type
    assert_equal Reading::ZERO, none.reading
    assert_equal [0.0] * 6, none.values
    assert_same none, none.close
    assert Sensor.first.none? unless Sensor.any?
  end

  def test_type_names_follow_sdl
    assert_equal 1, Sensor.type_index(:accelerometer)
    assert_equal 2, Sensor.type_index("gyroscope")
    assert_raises(ArgumentError) { Sensor.type_index(:barometer) }
  end

  def test_readings_are_values
    reading = Reading.from([3, 4, 0, 99])
    assert_equal Reading[3.0, 4.0, 0.0], reading
    assert_in_delta 5.0, reading.magnitude
    refute reading.at_rest?
    assert Reading::ZERO.at_rest?
    assert_equal "(3.000, 4.000, 0.000)", reading.to_s
    assert_in_delta Sensor::GRAVITY, Reading[0, Sensor::GRAVITY, 0].magnitude
  end
end
