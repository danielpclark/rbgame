# frozen_string_literal: true

module Gorillas
  module Scenes
    # The game itself: rounds of aiming, flying bananas and explosions,
    # until the match is over.
    class Play < Base
      NEXT_ROUND_SECONDS = 1.5

      def enter = start_round
      def leave = @field.dispose

      def handle(event)
        controller.handle(event, @aim) if round.aiming?
        throw_if_aimed
        nil
      end

      def draw(canvas)
        @field.draw(canvas)
        View::Scoreboard.new(match).draw(canvas)
        if round.aiming?
          typography(canvas).questionnaire(@aim, at: aim_corner, align: round.thrower.left? ? :left : :right, line_height: 10)
        elsif round.over?
          typography(canvas).title("#{round.winner} wins the round!", y: 60)
        end
      end

      private

      attr_reader :round

      def tick(dt)
        round.update(dt)
        if round.aiming?
          ask_for_aim unless @aim # the turn just passed
          controller.update(dt)
          throw_if_aimed
        elsif round.over?
          @over_for += dt
          finish_round if @over_for >= NEXT_ROUND_SECONDS
        end
      end

      def start_round
        @field&.dispose
        @round = match.new_round(listener: jukebox)
        @field = View::FieldView.new(round)
        @over_for = 0.0
        ask_for_aim
      end

      def ask_for_aim
        @aim = Questionnaire.new([
          Prompt.new(:angle, "Angle: ", numeric: true, max_length: 3),
          Prompt.new(:velocity, "Velocity: ", numeric: true, max_length: 3)
        ])
        controller.ask(@aim) { game.autoplayer.aim(round).to_answers }
      end

      def throw_if_aimed
        return unless @aim&.done?

        round.throw(@aim[:angle], @aim[:velocity])
        @aim = nil
      end

      # Returns the next scene once the match is decided.
      def finish_round
        return GameOver.new(game) if match.over?

        start_round
        nil
      end

      def aim_corner = round.thrower.left? ? [4, 16] : [Field::WIDTH - 4, 16]
    end
  end
end
