# frozen_string_literal: true

require "test_helper"

class KeyboardTest < Minitest::Test
  def setup = RbgameTest.screen

  def test_state_queries_run_headless
    refute Rbgame::Keyboard.pressed?(:a)
    assert_equal [], Rbgame::Keyboard.pressed
    refute Rbgame::Keyboard.shift?
    assert_kind_of Integer, Rbgame::Keyboard.modifiers
  end

  def test_key_still_answers_for_convenience
    refute Rbgame::Key.pressed?(:space)
  end
end
