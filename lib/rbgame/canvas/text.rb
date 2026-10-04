# frozen_string_literal: true

module Rbgame
  class Canvas
    # Text in SDL's built-in 8x8 font, until a font library arrives.
    #
    #   screen.text("Hello", at: [8, 8], scale: 2, align: :center)
    module Text
      FONT_SIZE = 8

      # `align` is :left, :center or :right relative to `at`.
      def text(string, at:, color: :white, scale: 1, align: :left)
        string = string.to_s
        at = Vector.coerce(at)
        x = aligned_x(at.x, text_width(string, scale: scale), align)
        paint(color)
        scaled(scale) { renderer.debug_text(x / scale, at.y / scale, string) }
        self
      end

      def text_width(string, scale: 1) = string.to_s.length * FONT_SIZE * scale
      def text_height(scale: 1) = FONT_SIZE * scale

      private

      def aligned_x(x, width, align)
        case align
        when :center then x - (width / 2.0)
        when :right then x - width
        else x
        end
      end

      # Runs the block with the renderer scaled up, then puts it back.
      def scaled(factor)
        sx, sy = renderer.scale
        renderer.set_scale(sx * factor, sy * factor)
        yield
      ensure
        renderer.set_scale(sx, sy)
      end
    end

    include Text
  end
end
