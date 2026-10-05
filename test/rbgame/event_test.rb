# frozen_string_literal: true

require "test_helper"

class EventTest < Minitest::Test
  Event = Rbgame::Event

  def key_down(key: 27, name: "Escape", modifiers: 0, repeat: false)
    Event.from_hash(type: :key_down, timestamp_ns: 1, window_id: 1, key: key, scancode: 41,
                    name: name, modifiers: modifiers, repeat: repeat)
  end

  def test_builds_the_right_class
    assert_instance_of Event::Quit, Event.from_hash(type: :quit, timestamp_ns: 5)
    assert_instance_of Event::KeyDown, key_down
    assert_instance_of Event::Unknown, Event.from_hash(type: :never_heard_of_it, timestamp_ns: 5)
  end

  def test_key_helpers
    event = key_down(modifiers: Rbgame::Key::Mod::LSHIFT)
    assert_equal :escape, event.sym
    assert event.key?(:escape)
    assert event.key?(:esc)
    assert event.shift?
    refute event.ctrl?
    assert_equal "a", key_down(key: 97, name: "A").char
    assert_nil event.char
  end

  def test_key_events_pattern_match_on_sym
    matched =
      case key_down(key: 32, name: "Space")
      in Event::KeyDown[sym: :space, repeat: false] then :space
      in Event::KeyDown then :other
      end
    assert_equal :space, matched
  end

  def test_touch_events_are_fractions_of_the_window
    event = Event.from_hash(type: :finger_motion, timestamp_ns: 1, window_id: 1, touch_id: 2, finger_id: 3,
                            x: 0.5, y: 0.25, dx: 0.01, dy: -0.02, pressure: 1.0)
    assert_instance_of Event::FingerMotion, event
    assert_equal Rbgame::Vector[0.5, 0.25], event.pos
    assert_equal Rbgame::Vector[0.01, -0.02], event.rel
    case event
    in Event::FingerMotion[pos:, finger_id: 3] then assert_equal 0.5, pos.x
    end
    assert_instance_of Event::FingerDown, Event.from_hash(type: :finger_down, timestamp_ns: 1, touch_id: 2, finger_id: 3, x: 0.0, y: 0.0, dx: 0.0, dy: 0.0, pressure: 1.0)
  end

  def test_mouse_events
    event = Event.from_hash(type: :mouse_down, timestamp_ns: 1, window_id: 1, x: 3.0, y: 4.0, button: 1, clicks: 2)
    assert event.left?
    assert event.double_click?
    assert_equal :left, event.button
    assert_equal Rbgame::Vector[3.0, 4.0], event.pos
    case event
    in Event::MouseDown[button: :left, pos:]
      assert_equal 3.0, pos.x
    end
  end

  def test_window_events
    event = Event.from_hash(type: :window, timestamp_ns: 1, window_id: 1, event: :resized, data1: 800, data2: 600)
    assert event.resized?
    assert_equal Rbgame::Vector[800, 600], event.size
  end

  def test_events_are_immutable
    assert key_down.frozen?
  end
end
