# frozen_string_literal: true

require "test_helper"

class KeyTest < Minitest::Test
  Key = Rbgame::Key

  def test_names_round_trip_through_sdl
    %i[escape space a left f1 return left_shift keypad_1].each do |key|
      code = Key.code(key)
      refute_equal 0, code
      assert_equal key, Key.sym(code), "#{key} came back as #{Key.sym(code)}"
    end
    assert_equal :"1", Key.sym(Key.code(:"1"))
  end

  def test_aliases
    assert_equal Key.code(:return), Key.code(:enter)
    assert_equal Key.code(:escape), Key.code(:esc)
    assert_equal :escape, Key.symbolize("Escape")
  end

  def test_integers_pass_through
    assert_equal 27, Key.code(27)
  end

  def test_unknown_key
    assert_raises(ArgumentError) { Key.code(:no_such_key_anywhere) }
  end

  def test_state_queries_run_headless
    refute Key.pressed?(:a)
    assert_equal [], Key.pressed
    assert_kind_of Integer, Key.modifiers
  end
end
