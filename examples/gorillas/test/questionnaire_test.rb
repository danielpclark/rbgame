# frozen_string_literal: true

require "test_helper"

class QuestionnaireTest < Minitest::Test
  Questionnaire = Gorillas::Questionnaire
  Prompt = Gorillas::Prompt

  def questionnaire
    Questionnaire.new([
      Prompt.new(:name, "Name: ", default: "Anon"),
      Prompt.new(:angle, "Angle: ", numeric: true)
    ])
  end

  def test_asks_in_order_and_collects_by_key
    q = questionnaire
    assert_equal :name, q.current.key
    assert_equal [:name], q.map(&:key), "only the current prompt shows at first"
    q.handle(GorillasTest.key(:return))
    assert_equal :angle, q.current.key
    assert_equal %i[name angle], q.map(&:key)
    q.type("30").submit
    assert q.done?
    assert_nil q.current
    assert_equal({ name: "Anon", angle: 30.0 }, q.answers)
    assert_equal 30.0, q[:angle]
  end

  def test_an_unacceptable_answer_keeps_the_prompt
    q = questionnaire
    q.submit
    q.submit # angle: empty, no default
    assert_equal :angle, q.current.key
    refute q.done?
  end

  def test_input_after_done_is_ignored
    q = questionnaire
    q.submit.type("1").submit
    assert q.done?
    q.type("9").submit
    assert_equal 1.0, q[:angle]
  end
end
