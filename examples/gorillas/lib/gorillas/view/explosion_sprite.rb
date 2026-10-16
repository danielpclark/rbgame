# frozen_string_literal: true

module Gorillas
  module View
    # The fireball: discs that grow, drawn with CIRCLE's squash so they are
    # round on the stretched field, like the crater they leave.
    class ExplosionSprite
      def initialize(explosion)
        @explosion = explosion
      end

      def draw(canvas)
        Ega.disc(canvas, @explosion.center, @explosion.radius, Palette::EXPLOSION)
        Ega.disc(canvas, @explosion.center, @explosion.radius * 0.5, Palette::EXPLOSION_CORE) if @explosion.radius > 4
      end
    end
  end
end
