# frozen_string_literal: true

module Gorillas
  # One line of QBasic INPUT: a label, what has been typed so far, and an
  # answer once Return is pressed with something acceptable.
  class Prompt
    attr_reader :key, :label, :buffer, :default

    def initialize(key, label, default: nil, numeric: false, max_length: 10)
      @key = key
      @label = label
      @default = default
      @numeric = numeric
      @max_length = max_length
      @buffer = +""
      @done = false
    end

    def numeric? = @numeric
    def done? = @done

    # The typed value, or the default when nothing was typed.
    def value
      text = buffer.empty? ? default.to_s : buffer
      numeric? ? Float(text) : text
    end

    def handle(event)
      return self unless event.is_a?(Rbgame::Event::KeyDown)

      case event.sym
      when :return, :keypad_enter then submit
      when :backspace then buffer.chop!
      when :escape then buffer.clear
      else type(typed_char(event))
      end
      self
    end

    def type(text)
      text.to_s.each_char { |char| buffer << char if accepts?(char) && buffer.length < @max_length }
      self
    end

    def submit = tap { @done = true if acceptable? }
    def display_text = "#{label}#{buffer}"

    private

    def accepts?(char) = !numeric? || char.match?(/[0-9.\-]/)

    def acceptable?
      value
      true
    rescue ArgumentError, TypeError
      false
    end

    def typed_char(event)
      char = event.char or return nil
      event.shift? ? char.upcase : char.downcase
    end
  end
end
