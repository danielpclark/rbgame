# frozen_string_literal: true

module Gorillas
  # Prompts asked in order; the answers are collected by key.
  #
  #   q = Questionnaire.new([Prompt.new(:angle, "Angle: ", numeric: true), ...])
  #   q.handle(event) until q.done?
  #   q[:angle]
  class Questionnaire
    include Enumerable

    attr_reader :prompts

    def initialize(prompts)
      @prompts = prompts.freeze
      @answered = 0
    end

    def current = prompts[@answered]
    def done? = current.nil?

    # The prompts shown so far: the answered ones and the current one.
    def each(&) = prompts.first(@answered + 1).each(&)
    def current?(prompt) = prompt.equal?(current)

    def handle(event) = feed { current.handle(event) }
    def type(text) = feed { current.type(text) }
    def submit = feed { current.submit }

    def [](key) = answers.fetch(key)
    def answers = prompts.first(@answered).to_h { |prompt| [prompt.key, prompt.value] }

    private

    def feed
      return self if done?

      yield
      @answered += 1 if current.done?
      self
    end
  end
end
