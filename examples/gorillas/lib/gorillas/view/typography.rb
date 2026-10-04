# frozen_string_literal: true

module Gorillas
  module View
    # Text on the field in the game's house style: centred titles,
    # paragraphs, and prompts with a blinking cursor.
    class Typography
      LINE_HEIGHT = 12

      def initialize(canvas)
        @canvas = canvas
      end

      def title(text, y:, scale: 2, color: Palette::TEXT)
        @canvas.text(text, at: [Field::WIDTH / 2, y], color: color, scale: scale, align: :center)
      end

      def paragraph(lines, y:, color: Palette::TEXT)
        lines.each_with_index { |line, i| title(line, y: y + (i * LINE_HEIGHT), scale: 1, color: color) }
      end

      def line(text, at:, color: Palette::TEXT, align: :left)
        @canvas.text(text, at: at, color: color, align: align)
      end

      # The prompts of a questionnaire, one per line, cursor on the current.
      def questionnaire(questionnaire, at:, align: :left, line_height: LINE_HEIGHT)
        x, y = Rbgame::Vector.coerce(at).to_a
        questionnaire.each_with_index do |prompt, i|
          text = prompt.display_text
          text += "_" if questionnaire.current?(prompt) && Blink.on?
          line(text, at: [x, y + (i * line_height)], align: align)
        end
      end
    end

    # A shared blink, on and off three times a second.
    module Blink
      def self.on? = (Rbgame::Clock.now * 3).floor.even?
    end
  end
end
