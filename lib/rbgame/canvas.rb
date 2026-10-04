# frozen_string_literal: true

module Rbgame
  # Everything you draw, you draw on a Canvas. The screen is one; a texture
  # being rendered to is one.
  #
  # The Canvas itself is the surface's state: its size, the clear colour,
  # clipping, blending, the logical resolution, and reading it back. What is
  # drawn on it comes from three concerns mixed in:
  #
  #   Canvas::Shapes   fill_rect, stroke_rect, line, circle, polygon ...
  #   Canvas::Text     text in SDL's 8x8 font
  #   Canvas::Images   textures, draw, render targets
  #
  # Colours accept anything Color.coerce takes, points anything
  # Vector.coerce takes, rectangles anything Rect.coerce takes.
  class Canvas
    attr_reader :renderer

    def initialize(renderer)
      @renderer = renderer
    end

    def output_size = Vector.new(*renderer.output_size)

    # The logical size when one is set, else the output size.
    def size
      w, h, mode = renderer.logical_presentation
      mode.zero? ? output_size : Vector.new(w, h)
    end

    def width = size.x
    def height = size.y
    def bounds = Rect.new(0, 0, width, height)
    def center = bounds.center

    # Clears the whole canvas to a colour.
    def fill(color)
      paint(color)
      renderer.clear
      self
    end
    alias clear fill

    # Restricts drawing to `rect` for the block.
    def clip(rect)
      renderer.set_clip_rect(*Rect.coerce(rect).round.to_a)
      yield self
    ensure
      renderer.set_clip_rect(nil, nil, nil, nil)
    end

    def blend_mode=(mode)
      renderer.blend_mode = BLEND_MODES.code(mode)
    end

    def blend_mode = BLEND_MODES.name(renderer.blend_mode)

    # A device-independent resolution; SDL scales it to the output
    # (letterboxed). nil turns it off.
    def logical_size=(size)
      size.nil? ? renderer.set_logical_presentation(0, 0, 0) : set_logical_size(size)
    end

    def set_logical_size(size, mode: :letterbox)
      size = Vector.coerce(size)
      renderer.set_logical_presentation(size.x.round, size.y.round, PRESENTATION_MODES.code(mode))
    end

    # Window coordinates (as mouse events report them) to canvas coordinates.
    def from_window(pos)
      pos = Vector.coerce(pos)
      Vector.new(*renderer.coordinates_from_window(pos.x, pos.y))
    end

    # The current contents as a Surface.
    def to_surface(rect = nil)
      rect = rect && Rect.coerce(rect).round
      Surface.new(renderer.read_pixels(*(rect ? rect.to_a : [nil] * 4)))
    end

    def screenshot(path) = to_surface.save(path)

    private

    # Sets the renderer's draw colour for what comes next.
    def paint(color)
      renderer.set_draw_color(*Color.coerce(color).to_a)
    end
  end
end
