# frozen_string_literal: true

require "test_helper"

class ClockTest < Minitest::Test
  def test_tick_holds_a_frame_rate
    clock = Rbgame::Clock.new
    started = Rbgame::Clock.now
    5.times { clock.tick(100) }
    # The guarantee is a floor: a frame lasts at least 1/fps. A busy CI
    # runner can make frames longer, never shorter.
    assert_operator Rbgame::Clock.now - started, :>=, 0.045
    assert_operator clock.fps, :<=, 110
    assert_operator clock.fps, :>, 0
    assert_equal 5, clock.frames
    assert_operator clock.frame_time, :>, 0
  end

  def test_sleep
    started = Rbgame::Clock.now
    Rbgame::Clock.sleep(0.02)
    assert_operator Rbgame::Clock.now - started, :>=, 0.019
  end
end
