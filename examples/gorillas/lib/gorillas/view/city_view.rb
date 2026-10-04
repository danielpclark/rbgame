# frozen_string_literal: true

module Gorillas
  module View
    # The terrain as a texture, re-uploaded only when a crater changed it.
    class CityView
      def initialize(terrain)
        @terrain = terrain
        @texture = nil
        @version = nil
      end

      def draw(canvas)
        refresh(canvas) if @version != @terrain.version
        canvas.draw(@texture, at: [0, 0])
      end

      def dispose = @texture&.destroy

      private

      def refresh(canvas)
        @texture&.destroy
        @texture = canvas.texture(@terrain.surface)
        @version = @terrain.version
      end
    end
  end
end
