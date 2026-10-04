# frozen_string_literal: true

module Gorillas
  # Types answers into a questionnaire one keystroke at a time, so a game
  # playing itself still looks like somebody at the keyboard.
  class Typist
    DEFAULT_PACE = 0.08 # seconds per keystroke

    def initialize(questionnaire, answers, pace: DEFAULT_PACE)
      @questionnaire = questionnaire
      @answers = answers.transform_values(&:to_s)
      @pace = pace
      @pending = nil
      @since_keystroke = 0.0
    end

    def update(dt)
      @since_keystroke += dt
      while @since_keystroke >= @pace && !@questionnaire.done?
        @since_keystroke -= @pace
        keystroke
      end
      self
    end

    def done? = @questionnaire.done?

    private

    def keystroke
      @pending ||= @answers.fetch(@questionnaire.current.key, "").each_char.to_a
      if @pending.empty?
        @questionnaire.submit
        @pending = nil
      else
        @questionnaire.type(@pending.shift)
      end
    end
  end
end
