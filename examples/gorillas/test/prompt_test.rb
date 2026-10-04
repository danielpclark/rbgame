# frozen_string_literal: true

require "test_helper"

class PromptTest < Minitest::Test
  Prompt = Gorillas::Prompt

  def key(sym, char = nil, shift: false)
    name = char || sym.to_s.capitalize
    code = char ? char.ord : Rbgame::Key.code(sym)
    Rbgame::Event::KeyDown.new(timestamp_ns: 0, window_id: 1, key: code, scancode: 0, name: name,
                               modifiers: shift ? Rbgame::Key::Mod::LSHIFT : 0, repeat: false)
  end

  def test_numeric_input
    prompt = Prompt.new("Angle: ", numeric: true, max_length: 3)
    prompt.handle(key(:"4", "4")).handle(key(:"5", "5")).handle(key(:a, "a"))
    assert_equal "45", prompt.buffer
    refute prompt.done?
    prompt.handle(key(:return))
    assert prompt.done?
    assert_equal 45.0, prompt.value
  end

  def test_empty_numeric_prompt_without_default_will_not_submit
    prompt = Prompt.new("Velocity: ", numeric: true)
    prompt.handle(key(:return))
    refute prompt.done?
  end

  def test_defaults_and_editing
    prompt = Prompt.new("Name: ", default: "Player 1")
    prompt.handle(key(:return))
    assert_equal "Player 1", prompt.value
    prompt = Prompt.new("Name: ")
    prompt.handle(key(:a, "a", shift: true)).handle(key(:b, "b")).handle(key(:backspace))
    assert_equal "A", prompt.buffer
    prompt.handle(key(:escape))
    assert_equal "", prompt.buffer
  end
end
