# frozen_string_literal: true

require "test_helper"

class VideoDriverTest < Minitest::Test
  VideoDriver = Rbgame::VideoDriver

  def test_an_explicit_driver_wins
    assert_equal "x11", VideoDriver.choose(requested: "x11", env: { "RBGAME_VIDEO_DRIVER" => "wayland" }, available: %w[x11 wayland dummy])
  end

  def test_the_environment_comes_next
    assert_equal "wayland", VideoDriver.choose(requested: nil, env: { "RBGAME_VIDEO_DRIVER" => "wayland" }, available: %w[x11 wayland])
  end

  def test_sdl_chooses_when_a_real_driver_exists
    assert_nil VideoDriver.choose(requested: nil, env: {}, available: %w[x11 dummy offscreen])
  end

  def test_offscreen_when_only_headless_drivers_exist
    assert_equal "offscreen", VideoDriver.choose(requested: nil, env: {}, available: %w[offscreen dummy])
  end

  def test_headless_knows_its_drivers
    assert VideoDriver.headless?("offscreen")
    assert VideoDriver.headless?("dummy")
    refute VideoDriver.headless?("x11")
  end
end

class SubsystemsTest < Minitest::Test
  def test_started_subsystems_report_so
    RbgameTest.screen
    assert Rbgame::Subsystems.video.started?
    assert Rbgame::Subsystems.audio.started?
    assert Rbgame.initialized?(:video)
    assert Rbgame.headless?
  end
end
