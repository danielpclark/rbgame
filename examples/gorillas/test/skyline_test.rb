# frozen_string_literal: true

require "test_helper"

class SkylineTest < Minitest::Test
  Skyline = Gorillas::Skyline
  Field = Gorillas::Field

  def test_fills_the_field_without_overlap
    skyline = Skyline.generate(rng: Random.new(3))
    assert_operator skyline.length, :>=, 5
    skyline.each_cons(2) { |a, b| assert_operator b.x, :>=, a.right }
    assert_operator skyline.buildings.last.right, :<=, Field::WIDTH
    skyline.each do |building|
      assert_includes Skyline::MIN_HEIGHT..Skyline::MAX_HEIGHT, building.height
      assert_includes Gorillas::Palette::BUILDINGS, building.color
      assert_equal Field::STREET, building.rect.bottom
    end
  end

  def test_is_deterministic_for_a_seed
    a = Skyline.generate(rng: Random.new(9)).buildings
    b = Skyline.generate(rng: Random.new(9)).buildings
    assert_equal a, b
  end

  def test_windows_stay_inside_their_building
    Skyline.generate(rng: Random.new(5)).each do |building|
      building.windows.each do |window|
        assert building.rect.contains?(window.rect), "#{window.rect} outside #{building.rect}"
        assert_includes [Gorillas::Palette::WINDOW_LIT, Gorillas::Palette::WINDOW_DARK], window.color
      end
    end
  end

  def test_slopes_shape_the_city
    rising = Array.new(50) { |i| Skyline.generate(rng: Random.new(i)) }.find { |s| s.slope == :rising }
    refute_nil rising
    first, last = rising.buildings.first.height, rising.buildings.last.height
    assert_operator last, :>=, first - Skyline::HEIGHT_STEP * 6
  end

  def test_building_under
    skyline = Skyline.generate(rng: Random.new(3))
    building = skyline.buildings[2]
    assert_equal building, skyline.building_under(building.center_x)
  end

  def test_gorilla_roofs_are_near_the_ends
    skyline = Skyline.generate(rng: Random.new(3))
    left, right = skyline.gorilla_roofs(Random.new(1))
    assert_operator left.x, :<, Field::WIDTH / 2
    assert_operator right.x, :>, Field::WIDTH / 2
    assert_equal skyline.building_under(left.x).top, left.y
  end

  def test_every_slope_builds_a_city
    Skyline::Slope::ALL.each do |slope|
      buildings = Skyline::Architect.new(slope, Random.new(2)).to_a
      assert_operator buildings.length, :>=, 5, slope.name.to_s
    end
  end
end
