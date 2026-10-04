# frozen_string_literal: true

module Gorillas
  module Scenes
    # Final score, and a way out.
    class GameOver < Base
      AUTOPLAY_SECONDS = 3.0

      def enter
        @elapsed = 0.0
      end

      def handle(event)
        game.stop if any_key?(event)
        nil
      end

      def update(dt)
        @elapsed += dt
        game.stop if options.autoplay && @elapsed >= AUTOPLAY_SECONDS
        nil
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        title(canvas, "GAME OVER!", y: 60, scale: 3)
        title(canvas, "Score:", y: 120, scale: 2)
        match.players.each_with_index do |player, i|
          canvas.text(player.name.ljust(12) + player.score.to_s.rjust(3), at: [Field::WIDTH / 2, 150 + (i * 14)],
                      color: Palette::TEXT, align: :center)
        end
        title(canvas, "#{match.winner.name} wins!", y: 200, scale: 2, color: Palette::SUN) if match.winner
        title(canvas, "Press any key to exit", y: 260, scale: 1, color: Palette::TEXT_DIM)
        winner_gorilla = Gorilla.new(feet: [320, 330], pose: (@elapsed * 4).floor.even? ? :left_up : :right_up)
        winner_gorilla.draw(canvas)
      end
    end
  end
end
