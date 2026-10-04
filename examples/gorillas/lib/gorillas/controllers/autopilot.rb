# frozen_string_literal: true

module Gorillas
  module Controllers
    # Nobody at the keyboard: questions are answered by a Typist from the
    # block given to `ask`, which is only evaluated here (a Keyboard never
    # needs the answers, so it never computes them).
    class Autopilot
      def initialize(pace: Typist::DEFAULT_PACE)
        @pace = pace
        @typist = nil
      end

      def ask(questionnaire)
        @typist = Typist.new(questionnaire, yield, pace: @pace)
      end

      def handle(_event, _questionnaire); end
      def update(dt) = @typist&.update(dt)
      def unattended? = true
    end
  end
end
