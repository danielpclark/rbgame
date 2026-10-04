# frozen_string_literal: true

module Rbgame
  # An image uploaded to a Canvas's renderer, cheap to draw every frame.
  # Create one with Canvas#texture; it belongs to that canvas.
  class Texture
    attr_reader :native, :renderer

    def initialize(native, renderer)
      @native = native
      @renderer = renderer
      @destroyed = false
    end

    def width = native.width
    def height = native.height
    def size = Vector.new(width, height)
    def bounds = Rect.new(0, 0, width, height)

    def alpha=(alpha)
      renderer.set_texture_alpha_mod(native, alpha)
    end

    def color_mod=(color)
      renderer.set_texture_color_mod(native, *Color.coerce(color).rgb)
    end

    def blend_mode=(mode)
      renderer.set_texture_blend_mode(native, BLEND_MODES.code(mode))
    end

    def scale_mode=(mode)
      renderer.set_texture_scale_mode(native, SCALE_MODES.code(mode))
    end

    # A Texture is its own texture; see Surface#with_texture.
    def with_texture(_canvas)
      yield self
    end

    # Frees the texture now instead of when the canvas goes away.
    def destroy
      return if @destroyed

      renderer.destroy_texture(native)
      @destroyed = true
    end

    def destroyed? = @destroyed
    def inspect = "#<Rbgame::Texture #{width.round}x#{height.round}#{" destroyed" if destroyed?}>"
  end
end
