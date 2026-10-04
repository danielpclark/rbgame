# frozen_string_literal: true

module Gorillas
  module Scenes
    # A screen of the game. The game hands each scene events and time and
    # asks it to draw; a scene moves on by returning the next one from
    # `update` or `handle`.
    class Base
      attr_reader :game

      def initialize(game)
        @game = game
      end

      def options = game.options
      def match = game.match
      def enter; end
      def handle(_event) = nil
      def update(_dt) = nil
      def draw(_canvas); end

      private

      def title(canvas, text, y:, scale: 2, color: Palette::TEXT)
        canvas.text(text, at: [Field::WIDTH / 2, y], color: color, scale: scale, align: :center)
      end

      def paragraph(canvas, lines, y:, color: Palette::TEXT, line_height: 12)
        lines.each_with_index do |line, i|
          canvas.text(line, at: [Field::WIDTH / 2, y + (i * line_height)], color: color, align: :center)
        end
      end

      def any_key?(event) = event.is_a?(Rbgame::Event::KeyDown) && !event.repeat?
    end
  end
end
