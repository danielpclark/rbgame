# frozen_string_literal: true

require "test_helper"

class EventsTest < Minitest::Test
  Events = Rbgame::Events
  Event = Rbgame::Event

  def setup
    RbgameTest.screen
    # Opening the audio device makes SDL announce the devices it found, a
    # moment later and from its own thread; open it first and wait for the
    # queue to go quiet, so those announcements can't land mid-test.
    Rbgame::Mixer.default
    nil while Events.wait(timeout: 0.05)
  end

  def test_push_and_poll
    Events.push_user(42)
    Events.push_quit
    events = Events.to_a
    assert_includes events.map(&:class), Event::User
    assert_includes events.map(&:class), Event::Quit
    assert_equal 42, events.find { |e| e.is_a?(Event::User) }.code
    assert_nil Events.poll
  end

  def test_each_is_enumerable
    Events.push_user(1)
    Events.push_user(2)
    assert_equal [1, 2], Events.select { |e| e.is_a?(Event::User) }.map(&:code)
  end

  def test_wait_times_out
    assert_nil Events.wait(timeout: 0.01)
  end

  def test_wait_returns_a_pushed_event
    Events.push_user(9)
    event = Events.wait(timeout: 1)
    assert_instance_of Event::User, event
  end
end
