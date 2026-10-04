# frozen_string_literal: true

require "test_helper"

class ModeTest < Minitest::Test
  def test_named_modes_resolve_to_sdl_codes
    assert_equal 1, Rbgame::BLEND_MODES.code(:blend)
    assert_equal :blend, Rbgame::BLEND_MODES.name(1)
    assert_equal 2, Rbgame::SCALE_MODES.code(:pixel_art)
    assert_equal 1, Rbgame::FLIP_MODES.code(:horizontal)
    assert_equal 2, Rbgame::PRESENTATION_MODES.code(:letterbox)
  end

  def test_unknown_names_list_the_choices
    error = assert_raises(ArgumentError) { Rbgame::BLEND_MODES.code(:multiply) }
    assert_match(/blend mode/, error.message)
    assert_match(/mul/, error.message)
  end

  def test_codes_pass_through
    assert_equal 4, Rbgame::BLEND_MODES.code(4)
  end
end
