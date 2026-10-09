# frozen_string_literal: true

module Rbgame
  class Canvas
    # Text: in a Font when given one, else in SDL's built-in 8x8 font.
    #
    #   screen.text("Hello", at: [8, 8], scale: 2, align: :center)
    #   screen.text("Hello", at: [8, 8], font: title_font, color: :yellow)
    module Text
      FONT_SIZE = 8

      # `align` is :left, :center or :right relative to `at`. With `font:`,
      # `wrap:` is a width to break lines at.
      def text(string, at:, color: :white, scale: 1, align: :left, font: nil, wrap: nil)
        string = string.to_s
        at = Vector.coerce(at)
        return text_in_font(string, at, font, color, align, wrap) if font

        x = aligned_x(at.x, text_width(string, scale: scale), align)
        paint(color)
        scaled(scale) { renderer.debug_text(x / scale, at.y / scale, string) }
        self
      end

      def text_width(string, scale: 1, font: nil) = font ? font.measure(string).x : string.to_s.length * FONT_SIZE * scale
      def text_height(scale: 1, font: nil) = font ? font.height : FONT_SIZE * scale

      private

      def text_in_font(string, at, font, color, align, wrap)
        rendered = font.render(string, color: color, wrap: wrap)
        x = aligned_x(at.x, rendered.width, align)
        rendered.with_texture(self) { |texture| draw(texture, at: [x, at.y]) }
        self
      end

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
