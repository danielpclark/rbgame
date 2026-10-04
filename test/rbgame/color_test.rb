# frozen_string_literal: true

require "test_helper"

class ColorTest < Minitest::Test
  Color = Rbgame::Color

  def test_constructors
    assert_equal [255, 128, 0, 255], Color.new(255, 128, 0).to_a
    assert_equal 64, Color.new(1, 2, 3, 64).a
    assert_equal 64, Color.new(1, 2, 3, a: 64).a
    assert_equal 9, Color.new(r: 1, g: 2, b: 3, a: 9).a
  end

  def test_coerce_accepts_every_spelling
    red = Color::RED
    assert_equal red, Color[red]
    assert_equal red, Color[:red]
    assert_equal red, Color["red"]
    assert_equal red, Color["#ff0000"]
    assert_equal red, Color["ff0000"]
    assert_equal red, Color["#f00"]
    assert_equal red, Color[[255, 0, 0]]
    assert_equal red, Color[0xff0000]
    assert_equal 128, Color["#ff000080"].a
  end

  def test_rejects_nonsense
    assert_raises(ArgumentError) { Color.new(256, 0, 0) }
    assert_raises(ArgumentError) { Color[:no_such_colour] }
    assert_raises(TypeError) { Color[Object.new] }
  end

  def test_value_semantics
    assert_equal Color.new(1, 2, 3), Color.new(1, 2, 3)
    assert_equal Color.new(1, 2, 3).hash, Color.new(1, 2, 3).hash
    assert Color.new(1, 2, 3).frozen?
    assert_equal Color.new(1, 2, 3, 7), Color.new(1, 2, 3).with(a: 7)
  end

  def test_comparable
    assert Color::BLACK < Color::WHITE
    assert_equal Color::BLACK, [Color::WHITE, Color::BLACK].min
  end

  def test_lerp_and_shades
    assert_equal Color.new(128, 0, 128), Color::RED.lerp(:blue, 0.5)
    assert_equal Color::RED, Color::RED.lerp(:blue, -1)
    assert_equal Color::BLUE, Color::RED.lerp(:blue, 2)
    assert_equal Color.new(204, 0, 0), Color::RED.darken
    assert_equal Color.new(255, 51, 51), Color::RED.lighten
  end

  def test_hsv_round_trip
    assert_equal Color::GREEN, Color.from_hsv(120, 1, 1)
    hue, saturation, value = Color::EGA[1].to_hsv
    assert_in_delta 240, hue
    assert_in_delta 1.0, saturation
    assert_in_delta 0.667, value, 0.01
  end

  def test_hex_output
    assert_equal "#ff8000", Color::ORANGE.to_hex
    assert_equal "#ff800080", Color::ORANGE.with(a: 128).to_hex
  end

  def test_ega_palette_is_the_ibm_one
    assert_equal 16, Color::EGA.length
    assert_equal "#0000aa", Color::EGA[1].to_hex
    assert_equal "#ffff55", Color::EGA[14].to_hex
    assert_equal Color::EGA[14], Color[:ega_yellow]
  end
end
