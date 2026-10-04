# frozen_string_literal: true

module Gorillas
  module Scenes
    # The game itself: rounds of aiming, flying bananas and explosions,
    # until the match is over.
    class Play < Base
      NEXT_ROUND_SECONDS = 1.5

      def enter
        @autoplayer = Autoplayer.new(rng: match.rng, accuracy: options.accuracy) if options.autoplay
        new_round
      end

      def handle(event)
        return unless round.aiming? && !options.autoplay

        prompt&.handle(event)
        advance_prompt
        nil
      end

      def update(dt)
        round.update(dt)
        if round.aiming?
          update_aiming(dt)
        elsif round.over?
          @pause += dt
          finish_round if @pause >= NEXT_ROUND_SECONDS
        end
        return GameOver.new(game) if match.over? && round.over? && @pause >= NEXT_ROUND_SECONDS

        nil
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        draw_city(canvas)
        round.sun.draw(canvas)
        round.gorillas.each_value { |gorilla| gorilla.draw(canvas) }
        Banana.draw(canvas, round.banana_position, round.banana_frame) if round.flying? && round.banana_position
        round.explosion&.draw(canvas)
        round.wind.draw(canvas)
        draw_hud(canvas)
      end

      private

      attr_reader :round, :prompt

      def new_round
        @round = match.new_round
        @city_texture&.destroy
        @city_texture = nil
        @city_version = nil
        @pause = 0.0
        start_aiming
      end

      def start_aiming
        @prompts = [Prompt.new("Angle: ", numeric: true, max_length: 3), Prompt.new("Velocity: ", numeric: true, max_length: 3)]
        @prompt = @prompts.first
        @answers = []
        @think = 0.0
        @typing = nil
      end

      def update_aiming(dt)
        start_aiming if @prompts.nil? || (@prompts.all?(&:done?) && @answers.length == 2)
        return unless options.autoplay

        @think += dt
        return if @think < 0.08

        @think = 0.0
        @plan ||= @autoplayer.aim(round)
        @typing ||= (prompt.label.start_with?("Angle") ? @plan.angle : @plan.velocity).round.to_s.dup
        if @typing.empty?
          prompt.submit
          @typing = nil
        else
          prompt.type(@typing.slice!(0))
        end
        advance_prompt
      end

      def advance_prompt
        return unless prompt&.done?

        @answers << prompt.value
        @prompt = @prompts[@answers.length]
        return if @prompt

        angle, velocity = @answers
        @plan = nil
        round.throw(angle, velocity)
        @prompts = nil
      end

      def finish_round
        return if match.over?

        new_round
      end

      def draw_city(canvas)
        if @city_version != round.terrain.version
          @city_texture&.destroy
          @city_texture = canvas.texture(round.terrain.surface)
          @city_version = round.terrain.version
        end
        canvas.draw(@city_texture, at: [0, 0])
      end

      def draw_hud(canvas)
        canvas.text(match.left.name, at: [4, 4], color: Palette::TEXT)
        canvas.text(match.right.name, at: [Field::WIDTH - 4, 4], color: Palette::TEXT, align: :right)
        score = "#{match.left.score}>Score<#{match.right.score}"
        canvas.text(score, at: [Field::WIDTH / 2, Field::STREET + 4], color: Palette::TEXT, align: :center)

        if round.aiming? && @prompts
          x = round.thrower.left? ? 4 : Field::WIDTH - 4
          align = round.thrower.left? ? :left : :right
          @prompts.each_with_index do |p, i|
            next unless i <= @answers.length

            text = p.display_text
            text += "_" if p.equal?(prompt) && (Rbgame::Clock.now * 3).floor.even?
            canvas.text(text, at: [x, 16 + (i * 10)], color: Palette::TEXT, align: align)
          end
        elsif round.over? && round.winner
          title(canvas, "#{round.winner.name} wins the round!", y: 60, scale: 2)
        end
      end
    end
  end
end
