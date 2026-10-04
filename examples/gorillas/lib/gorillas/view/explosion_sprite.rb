# frozen_string_literal: true

module Gorillas
  module View
    class ExplosionSprite
      def initialize(explosion)
        @explosion = explosion
      end

      def draw(canvas)
        canvas.circle(@explosion.center, @explosion.radius, Palette::EXPLOSION)
        canvas.circle(@explosion.center, @explosion.radius * 0.5, Palette::EXPLOSION_CORE) if @explosion.radius > 4
      end
    end
  end
end
