# frozen_string_literal: true

require "test_helper"

class AnimationTest < Minitest::Test
  Animation = Rbgame::Animation
  Surface = Rbgame::Surface
  Color = Rbgame::Color
  Vector = Rbgame::Vector

  def frame(color)
    Surface.new([4, 4]).fill(color)
  end

  def setup
    @blink = Animation[frame(:red), frame(:green), frame(:blue), duration: 0.5]
  end

  def test_frames_and_timing
    assert_equal 3, @blink.count
    assert_in_delta 1.5, @blink.duration
    assert_equal Vector[4, 4], @blink.size
    assert_equal [0.5, 0.5, 0.5], @blink.map(&:duration)
  end

  def test_at_picks_the_frame_showing_and_loops
    assert_equal Color::RED, @blink.at(0.0)[0, 0]
    assert_equal Color::RED, @blink.at(0.49)[0, 0]
    assert_equal Color::GREEN, @blink.at(0.5)[0, 0]
    assert_equal Color::BLUE, @blink.at(1.2)[0, 0]
    assert_equal Color::RED, @blink.at(1.5)[0, 0], "loops"
    assert_equal Color::GREEN, @blink.at(3.7)[0, 0]
    assert_equal Color::BLUE, @blink.at(99, loop: false)[0, 0], "holds the last frame"
    assert_nil Animation.new([]).at(1)
  end

  def test_saves_and_loads_a_gif
    Dir.mktmpdir do |dir|
      path = File.join(dir, "blink.gif")
      @blink.save(path)
      loaded = Animation.load(path)
      assert_equal 3, loaded.count
      assert_in_delta 1.5, loaded.duration, 0.02
      assert_equal Color::RED, loaded.at(0)[1, 1]
      assert_equal Color::BLUE, loaded.at(1.2)[1, 1]
    end
  end
end
