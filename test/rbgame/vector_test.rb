# frozen_string_literal: true

require "test_helper"

class VectorTest < Minitest::Test
  Vector = Rbgame::Vector

  def test_arithmetic
    assert_equal Vector[4, 6], Vector[1, 2] + [3, 4]
    assert_equal Vector[-2, -2], Vector[1, 2] - Vector[3, 4]
    assert_equal Vector[2, 4], Vector[1, 2] * 2
    assert_equal Vector[2, 4], 2 * Vector[1, 2]
    assert_equal Vector[0.5, 1.0], Vector[1, 2] / 2
    assert_equal Vector[-1, -2], -Vector[1, 2]
    assert_equal Vector[3, 8], Vector[1, 2] * Vector[3, 4]
  end

  def test_coerce
    assert_equal Vector[1, 2], Vector.coerce([1, 2])
    assert_equal Vector[1, 2], Vector.coerce(x: 1, y: 2)
    assert_equal Vector[1, 2], Vector[[1, 2]]
    assert_raises(TypeError) { Vector.coerce(3) }
  end

  def test_measures
    assert_equal 5.0, Vector[3, 4].magnitude
    assert_equal 25, Vector[3, 4].magnitude_squared
    assert_equal 11, Vector[1, 2].dot([3, 4])
    assert_equal 5.0, Vector[0, 0].distance_to([3, 4])
    assert_in_delta 1.0, Vector[3, 4].normalize.magnitude
    assert_equal Vector::ZERO, Vector::ZERO.normalize
  end

  def test_angles_are_degrees_counter_clockwise_with_y_down
    assert_in_delta 90, Vector[0, -1].angle
    assert_in_delta 0, Vector[1, 0].angle
    assert_equal Vector[0, -10], Vector.polar(90, 10).round
    assert_equal Vector[0, -1], Vector[1, 0].rotate(90).round
    assert_equal Vector[-1, 0], Vector[1, 0].rotate(180).round
  end

  def test_lerp
    assert_equal Vector[5.0, 5.0], Vector[0, 0].lerp([10, 10], 0.5)
  end

  def test_pattern_matching
    case Vector[1, 2]
    in { x:, y: }
      assert_equal [1, 2], [x, y]
    end
  end
end
