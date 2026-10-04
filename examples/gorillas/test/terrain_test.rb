# frozen_string_literal: true

require "test_helper"

class TerrainTest < Minitest::Test
  def setup
    GorillasTest.init!
    @skyline = Gorillas::Skyline.generate(rng: Random.new(3))
    @terrain = Gorillas::Terrain.new(@skyline)
  end

  def test_buildings_are_solid_and_the_sky_is_not
    building = @skyline.buildings[1]
    assert @terrain.solid?(building.rect.center)
    refute @terrain.solid?([building.center_x, building.top - 5])
    refute @terrain.solid?([-1, 10])
  end

  def test_craters_remove_terrain
    building = @skyline.buildings.max_by(&:height)
    point = building.rect.center
    version = @terrain.version
    @terrain.crater(point, 10)
    refute @terrain.solid?(point)
    assert @terrain.solid?(point + [0, 14]) if building.rect.contains?(point + [0, 14])
    assert_operator @terrain.version, :>, version
  end
end
