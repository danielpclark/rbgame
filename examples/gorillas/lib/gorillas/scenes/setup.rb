# frozen_string_literal: true

module Gorillas
  module Scenes
    # The questions GORILLA.BAS asked before a game, typed one at a time.
    class Setup < Base
      def enter
        @questions = Questionnaire.new([
          Prompt.new(:name1, "Name of Player 1 (Default = 'Player 1'): ", default: "Player 1"),
          Prompt.new(:name2, "Name of Player 2 (Default = 'Player 2'): ", default: "Player 2"),
          Prompt.new(:play_to, "Play to how many total points (Default = 3)? ", default: 3, numeric: true, max_length: 2),
          Prompt.new(:gravity, "Gravity in Meters/Sec (Earth = 9.8)? ", default: 9.8, numeric: true, max_length: 5)
        ])
        controller.ask(@questions) { options.setup_answers }
      end

      def handle(event)
        controller.handle(event, @questions)
        next_scene
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        text = typography(canvas)
        text.title(Intro::TITLE, y: 24, scale: 2)
        text.questionnaire(@questions, at: [40, 90], line_height: 24)
        text.line("(Esc clears the line, Enter accepts)", at: [40, 220], color: Palette::TEXT_DIM) unless controller.unattended?
      end

      private

      def tick(dt)
        controller.update(dt)
        next_scene
      end

      def next_scene
        return unless @questions.done?

        game.start_match(names: [@questions[:name1], @questions[:name2]],
                         play_to: @questions[:play_to].to_i.clamp(1, 99),
                         gravity: @questions[:gravity].then { |g| g.positive? ? g : Match::EARTH_GRAVITY })
        Play.new(game)
      end
    end
  end
end
