# frozen_string_literal: true

require "test_helper"

class TypistTest < Minitest::Test
  def test_types_one_key_per_pace_then_submits
    q = Gorillas::Questionnaire.new([
      Gorillas::Prompt.new(:angle, "Angle: ", numeric: true),
      Gorillas::Prompt.new(:velocity, "Velocity: ", numeric: true)
    ])
    typist = Gorillas::Typist.new(q, { angle: 45, velocity: "6" }, pace: 0.1)

    typist.update(0.1)
    assert_equal "4", q.current.buffer
    typist.update(0.1)
    assert_equal "45", q.current.buffer
    typist.update(0.1)
    assert_equal :velocity, q.current.key, "the third keystroke is Return"
    typist.update(0.25)
    assert q.done?
    assert typist.done?
    assert_equal({ angle: 45.0, velocity: 6.0 }, q.answers)
  end

  def test_missing_answers_submit_the_default
    q = Gorillas::Questionnaire.new([Gorillas::Prompt.new(:name, "Name: ", default: "Player 1")])
    Gorillas::Typist.new(q, {}, pace: 0.05).update(0.05)
    assert_equal "Player 1", q[:name]
  end
end
