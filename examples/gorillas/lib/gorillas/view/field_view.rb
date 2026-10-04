# frozen_string_literal: true

module Gorillas
  module View
    # Everything on the field during a round, back to front.
    class FieldView
      def initialize(round)
        @round = round
        @city = CityView.new(round.terrain)
      end

      def draw(canvas)
        canvas.fill(Palette::SKY)
        @city.draw(canvas)
        SunSprite.new(@round.sun).draw(canvas)
        @round.gorillas.each { |gorilla| GorillaSprite.new(gorilla).draw(canvas) }
        BananaSprite.new(@round.banana).draw(canvas) if @round.banana
        ExplosionSprite.new(@round.explosion).draw(canvas) if @round.explosion
        WindGauge.new(@round.wind).draw(canvas)
      end

      def dispose = @city.dispose
    end
  end
end
