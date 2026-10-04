# frozen_string_literal: true

module Gorillas
  module Scenes
    # The questions GORILLA.BAS asked before a game, typed one at a time.
    class Setup < Base
      def enter
        @prompts = [
          Prompt.new("Name of Player 1 (Default = 'Player 1'): ", default: "Player 1", max_length: 10),
          Prompt.new("Name of Player 2 (Default = 'Player 2'): ", default: "Player 2", max_length: 10),
          Prompt.new("Play to how many total points (Default = 3)? ", default: 3, numeric: true, max_length: 2),
          Prompt.new("Gravity in Meters/Sec (Earth = 9.8)? ", default: 9.8, numeric: true, max_length: 5)
        ]
        @index = 0
        @answers = []
        @elapsed = 0.0
        autofill if options.autoplay
      end

      def handle(event)
        return if options.autoplay

        current&.handle(event)
        advance
      end

      def update(dt)
        @elapsed += dt
        return unless options.autoplay

        # Pretend to type, one keystroke every few frames.
        @typing ||= @autofill.shift
        if @typing && @elapsed > 0.08
          @elapsed = 0.0
          if @typing.empty?
            current.submit
            @typing = nil
          else
            current.type(@typing.slice!(0))
          end
        end
        advance
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        title(canvas, "R u b y   G O R I L L A S", y: 24, scale: 2)
        @prompts.each_with_index do |prompt, i|
          next if i > @index

          text = prompt.display_text
          text += "_" if i == @index && (@elapsed * 3).floor.even?
          canvas.text(text, at: [40, 90 + (i * 24)], color: Palette::TEXT)
        end
        canvas.text("(Esc clears the line, Enter accepts)", at: [40, 220], color: Palette::TEXT_DIM) unless options.autoplay
      end

      private

      def current = @prompts[@index]

      def advance
        return unless current&.done?

        @answers << current.value
        @index += 1
        return if @index < @prompts.length

        names = @answers[0, 2].map(&:to_s)
        play_to = @answers[2].to_i.clamp(1, 99)
        gravity = @answers[3].to_f
        gravity = Match::EARTH_GRAVITY unless gravity.positive?
        game.start_match(names: names, play_to: play_to, gravity: gravity)
        Play.new(game)
      end

      def autofill
        @autofill = [options.names[0], options.names[1], options.play_to.to_s, options.gravity.to_s].map(&:dup)
      end
    end
  end
end
