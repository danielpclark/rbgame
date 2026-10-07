# frozen_string_literal: true

require "test_helper"

class ClipboardTest < Minitest::Test
  Clipboard = Rbgame::Clipboard
  Event = Rbgame::Event
  Events = Rbgame::Events

  def setup
    RbgameTest.screen
    Events.to_a
  end

  def test_text_round_trips
    Clipboard.text = "high score: 42"
    assert Clipboard.text?
    assert_equal "high score: 42", Clipboard.text
  end

  def test_clear_empties_it
    Clipboard.text = "something"
    Clipboard.clear
    refute Clipboard.text?
    assert_equal "", Clipboard.text
  end

  def test_no_image_is_nil
    Clipboard.text = "words, not pictures"
    assert_nil Clipboard.image
  end

  def test_setting_it_is_an_event
    Clipboard.text = "copied"
    updates = Events.grep(Event::ClipboardUpdate)
    refute_empty updates
    assert updates.last.owner?, "this program put the text there"
    assert_includes updates.last.mime_types.join, "text/plain"
  end
end
