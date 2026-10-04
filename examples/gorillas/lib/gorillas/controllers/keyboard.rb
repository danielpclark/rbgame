# frozen_string_literal: true

module Gorillas
  module Controllers
    # A person at the keyboard: events go to whatever is being asked.
    class Keyboard
      def ask(_questionnaire); end
      def handle(event, questionnaire) = questionnaire.handle(event)
      def update(_dt); end
      def unattended? = false
    end
  end
end
