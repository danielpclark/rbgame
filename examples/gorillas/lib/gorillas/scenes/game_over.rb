# frozen_string_literal: true

module Gorillas
  module Scenes
    # Final score, and a way out.
    class GameOver < Base
      UNATTENDED_SECONDS = 3.0

      def handle(event)
        game.stop if any_key?(event)
        nil
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        text = typography(canvas)
        text.title("GAME OVER!", y: 60, scale: 3)
        text.title("Score:", y: 120)
        match.players.each_with_index do |player, i|
          text.line(player.name.ljust(12) + player.score.to_s.rjust(3), at: [Field::WIDTH / 2, 150 + (i * 14)], align: :center)
        end
        text.title("#{match.winner} wins!", y: 200, color: Palette::SUN) if match.winner
        text.title("Press any key to exit", y: 260, scale: 1, color: Palette::TEXT_DIM)
        View::GorillaSprite.new(Gorilla.new(feet: [320, 330]).dancing((elapsed * 4).floor)).draw(canvas)
      end

      private

      def tick(_dt)
        game.stop if controller.unattended? && elapsed >= UNATTENDED_SECONDS
        nil
      end
    end
  end
end
