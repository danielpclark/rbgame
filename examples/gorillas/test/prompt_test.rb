# frozen_string_literal: true

require "test_helper"

class PromptTest < Minitest::Test
  Prompt = Gorillas::Prompt

  def key(...) = GorillasTest.key(...)

  def test_numeric_input
    prompt = Prompt.new(:angle, "Angle: ", numeric: true, max_length: 3)
    prompt.handle(key(:"4", "4")).handle(key(:"5", "5")).handle(key(:a, "a"))
    assert_equal "45", prompt.buffer
    refute prompt.done?
    prompt.handle(key(:return))
    assert prompt.done?
    assert_equal 45.0, prompt.value
    assert_equal :angle, prompt.key
  end

  def test_empty_numeric_prompt_without_default_will_not_submit
    prompt = Prompt.new(:velocity, "Velocity: ", numeric: true)
    prompt.handle(key(:return))
    refute prompt.done?
  end

  def test_defaults_and_editing
    prompt = Prompt.new(:name, "Name: ", default: "Player 1")
    prompt.handle(key(:return))
    assert_equal "Player 1", prompt.value
    prompt = Prompt.new(:name, "Name: ")
    prompt.handle(key(:a, "a", shift: true)).handle(key(:b, "b")).handle(key(:backspace))
    assert_equal "A", prompt.buffer
    prompt.handle(key(:escape))
    assert_equal "", prompt.buffer
  end

  def test_type_respects_the_limit_and_the_kind
    prompt = Prompt.new(:n, "N: ", numeric: true, max_length: 2)
    prompt.type("1x2345")
    assert_equal "12", prompt.buffer
  end
end
