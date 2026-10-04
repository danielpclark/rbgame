# frozen_string_literal: true

require "test_helper"

class ClockTest < Minitest::Test
  def test_tick_holds_a_frame_rate
    clock = Rbgame::Clock.new
    started = Rbgame::Clock.now
    5.times { clock.tick(100) }
    assert_operator Rbgame::Clock.now - started, :>=, 0.045
    assert_in_delta 100, clock.fps, 25
    assert_equal 5, clock.frames
    assert_operator clock.frame_time, :>, 0
  end

  def test_sleep
    started = Rbgame::Clock.now
    Rbgame::Clock.sleep(0.02)
    assert_operator Rbgame::Clock.now - started, :>=, 0.019
  end
end
