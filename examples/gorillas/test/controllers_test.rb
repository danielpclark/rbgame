# frozen_string_literal: true

require "test_helper"

class ControllersTest < Minitest::Test
  def questionnaire = Gorillas::Questionnaire.new([Gorillas::Prompt.new(:angle, "Angle: ", numeric: true)])

  def test_keyboard_passes_events_and_never_evaluates_answers
    keyboard = Gorillas::Controllers::Keyboard.new
    q = questionnaire
    keyboard.ask(q) { flunk "answers computed for a keyboard" }
    keyboard.handle(GorillasTest.key(:"7", "7"), q)
    keyboard.handle(GorillasTest.key(:return), q)
    keyboard.update(1.0)
    assert_equal 7.0, q[:angle]
    refute keyboard.unattended?
  end

  def test_autopilot_types_the_answers_and_ignores_the_keyboard
    autopilot = Gorillas::Controllers::Autopilot.new(pace: 0.01)
    q = questionnaire
    autopilot.ask(q) { { angle: 60 } }
    autopilot.handle(GorillasTest.key(:"1", "1"), q)
    assert_equal "", q.current.buffer
    autopilot.update(1.0)
    assert_equal 60.0, q[:angle]
    assert autopilot.unattended?
  end
end
