# frozen_string_literal: true

require "test_helper"

# Drives a virtual gamepad, which SDL treats like a real one, and reads it
# back through Rbgame::Gamepad and the event queue.
class GamepadTest < Minitest::Test
  Gamepad = Rbgame::Gamepad
  Event = Rbgame::Event
  Events = Rbgame::Events
  Vector = Rbgame::Vector

  def setup
    RbgameTest.screen
    @virtual = Gamepad::Virtual.attach(name: "Test pad")
    settle
  end

  def teardown
    @virtual.detach
    settle
  end

  # Pumps the queue so SDL reads the pad, and drains the events it made.
  def settle
    Events.pump
    Events.to_a
  end

  def pad = @virtual.gamepad

  def test_the_virtual_pad_starts_at_rest
    assert_equal [], pad.pressed
    assert_equal Vector::ZERO, pad.left_stick
    assert_equal Vector::ZERO, pad.right_stick
    assert_in_delta 0.0, pad.trigger(:left), 0.001
    assert_in_delta 0.0, pad.trigger(:right), 0.001
  end

  def test_a_plugged_in_pad_is_listed
    assert_includes Gamepad.all.map(&:id), @virtual.id
    assert_equal "Test pad", pad.name
    assert pad.connected?
    refute pad.none?
    assert_same pad, Gamepad.find(@virtual.id), "the same object for the same pad"
    assert pad.button?(:south)
    assert pad.axis?(:left_x)
  end

  def test_buttons_read_back_after_a_pump
    @virtual.press(:south).press(:dpad_left)
    settle
    assert pad.pressed?(:south)
    assert_equal %i[south dpad_left], pad.pressed

    @virtual.release(:south)
    settle
    refute pad.pressed?(:south)
    assert_equal %i[dpad_left], pad.pressed
  end

  def test_unknown_names_are_errors
    assert_raises(ArgumentError) { pad.pressed?(:fire) }
    assert_raises(ArgumentError) { pad.axis(:throttle) }
  end

  def test_sticks_are_vectors_with_a_dead_zone
    @virtual.move(:left_x, 0.05).move(:left_y, -0.05)
    settle
    assert_equal Vector::ZERO, pad.left_stick

    @virtual.move(:left_x, -1.0).move(:left_y, 0.5)
    settle
    assert_in_delta(-1.0, pad.left_stick.x, 0.001)
    assert_in_delta 0.5, pad.left_stick.y, 0.001
    assert_equal Vector::ZERO, pad.right_stick

    pad.dead_zone = 0.0
    @virtual.move(:left_x, 0.05).move(:left_y, 0.0)
    settle
    assert_in_delta 0.05, pad.left_stick.x, 0.001
  end

  def test_triggers_run_from_zero_to_one
    @virtual.move(:right_trigger, 0.5)
    settle
    assert_in_delta 0.5, pad.trigger(:right), 0.001
    assert_in_delta 0.0, pad.trigger(:left), 0.001
  end

  def test_button_events_name_the_button_and_the_pad
    @virtual.press(:east)
    Events.pump
    events = Events.to_a
    down = events.grep(Event::GamepadButtonDown)
    assert_equal 1, down.size
    assert_equal :east, down.first.button
    assert down.first.button?(:east)
    assert_same pad, down.first.gamepad

    case down.first
    in Event::GamepadButtonDown[button: :east, gamepad:] then assert_equal @virtual.id, gamepad.id
    end

    @virtual.release(:east)
    Events.pump
    assert_equal [:east], Events.grep(Event::GamepadButtonUp).map(&:button)
  end

  def test_axis_events_carry_the_value
    @virtual.move(:right_x, 0.75)
    Events.pump
    motion = Events.grep(Event::GamepadAxisMotion).find { |event| event.axis == :right_x }
    assert_in_delta 0.75, motion.value, 0.001
    assert_equal({ axis: :right_x }, motion.deconstruct_keys(nil).slice(:axis))
  end

  def test_plugging_in_and_out_are_events
    other = Gamepad::Virtual.attach(name: "Second pad")
    Events.pump
    added = Events.grep(Event::GamepadAdded)
    assert_equal [other.id], added.map(&:which)
    assert_equal "Second pad", added.first.gamepad.name

    other.detach
    Events.pump
    removed = Events.grep(Event::GamepadRemoved)
    assert_equal [other.id], removed.map(&:which)
    assert removed.first.gamepad.none?
    refute_includes Gamepad.all.map(&:id), other.id
  end

  def test_rumble_says_whether_the_pad_took_it
    # The virtual pad has neither a motor nor a light.
    refute pad.rumble(0.5, seconds: 0.1)
    refute pad.rumble_triggers(1.0, 0.0, seconds: 0.1)
    pad.led = :red
  end

  def test_none_stands_in_when_nothing_is_plugged_in
    @virtual.detach
    settle
    none = Gamepad.first
    assert none.none?
    refute Gamepad.any?
    refute none.pressed?(:south)
    assert_equal [], none.pressed
    assert_equal Vector::ZERO, none.left_stick
    assert_equal 0.0, none.trigger(:left)
    refute none.rumble(1.0)
    assert_equal "no gamepad", none.name
  end
end
