# frozen_string_literal: true

module Gorillas
  # A line of text being typed, as QBasic's INPUT drew it: a label, what
  # has been typed so far, and a blinking cursor. Fed key events; done when
  # Return is pressed with something acceptable in the buffer.
  class Prompt
    attr_reader :label, :buffer, :default

    def initialize(label, default: nil, numeric: false, max_length: 10)
      @label = label
      @default = default
      @numeric = numeric
      @max_length = max_length
      @buffer = +""
      @done = false
    end

    def numeric? = @numeric
    def done? = @done

    # The answer: the typed value, or the default when nothing was typed.
    def value
      text = buffer.empty? ? default.to_s : buffer
      numeric? ? Float(text) : text
    end

    def handle(event)
      return unless event.is_a?(Rbgame::Event::KeyDown)

      case event.sym
      when :return, :keypad_enter then submit
      when :backspace then buffer.chop!
      when :escape then buffer.clear
      else
        char = typed_char(event)
        buffer << char if char && buffer.length < @max_length
      end
      self
    end

    def type(text) = tap { text.each_char { |c| buffer << c if buffer.length < @max_length } }
    def submit = tap { @done = true if acceptable? }

    def display_text = "#{label}#{buffer}"

    private

    def acceptable?
      return true unless numeric?

      Float(value)
      true
    rescue ArgumentError, TypeError
      false
    end

    def typed_char(event)
      char = event.char
      return nil unless char

      if numeric?
        char if char.match?(/[0-9.\-]/)
      else
        event.shift? ? char.upcase : char.downcase
      end
    end
  end
end
