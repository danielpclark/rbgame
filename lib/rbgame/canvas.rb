# frozen_string_literal: true

module Rbgame
  # Everything you draw, you draw on a Canvas. The screen is one; a texture
  # being rendered to is one. Colours accept anything Color.coerce takes,
  # points anything Vector.coerce takes, rectangles anything Rect.coerce takes.
  #
  #   screen.fill(:black)
  #   screen.fill_rect([10, 10, 50, 20], :red)
  #   screen.circle([100, 100], 30, Color::EGA[14])
  #   screen.line([0, 0], [100, 50], :white, width: 3)
  #   screen.polygon([[0, 0], [40, 0], [20, 30]], "#88ccff")
  #   screen.text("Hello", at: [8, 8], scale: 2)
  #   screen.draw(sprite, at: [50, 50], angle: 45)
  class Canvas
    FONT_SIZE = 8 # SDL's debug font is 8x8
    PRESENTATION_MODES = { disabled: 0, stretch: 1, letterbox: 2, overscan: 3, integer_scale: 4 }.freeze

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
      set_color(color)
      renderer.clear
      self
    end
    alias clear fill

    def pixel(pos, color)
      set_color(color)
      pos = Vector.coerce(pos)
      renderer.point(pos.x, pos.y)
      self
    end

    def pixels(points, color)
      set_color(color)
      renderer.points(points.flat_map { |p| Vector.coerce(p).to_a })
      self
    end

    def line(from, to, color, width: 1)
      if width <= 1
        set_color(color)
        from = Vector.coerce(from)
        to = Vector.coerce(to)
        renderer.line(from.x, from.y, to.x, to.y)
      else
        polygon(Geometry.thick_line(from, to, width), color)
      end
      self
    end

    # A connected run of lines through `points`.
    def lines(points, color, closed: false, width: 1)
      points = points.map { |p| Vector.coerce(p) }
      points << points.first if closed && points.length > 1
      if width <= 1
        set_color(color)
        renderer.lines(points.flat_map(&:to_a))
      else
        points.each_cons(2) { |a, b| line(a, b, color, width: width) }
      end
      self
    end

    def fill_rect(rect, color)
      set_color(color)
      renderer.fill_rect(*Rect.coerce(rect).to_a)
      self
    end

    def stroke_rect(rect, color, width: 1)
      rect = Rect.coerce(rect)
      if width <= 1
        set_color(color)
        renderer.rect(*rect.to_a)
      else
        set_color(color)
        renderer.fill_rects([
          [rect.x, rect.y, rect.w, width],
          [rect.x, rect.bottom - width, rect.w, width],
          [rect.x, rect.y, width, rect.h],
          [rect.right - width, rect.y, width, rect.h]
        ].flatten)
      end
      self
    end

    # Filled by default; `fill: false` strokes the outline.
    def rect(rect, color, fill: true, width: 1)
      fill ? fill_rect(rect, color) : stroke_rect(rect, color, width: width)
    end

    def circle(center, radius, color, fill: true, width: 1, segments: nil)
      ellipse_at(center, radius, radius, color, fill: fill, width: width, segments: segments)
    end

    # An ellipse filling `rect`.
    def ellipse(rect, color, fill: true, width: 1, segments: nil)
      rect = Rect.coerce(rect)
      ellipse_at(rect.center, rect.w / 2.0, rect.h / 2.0, color, fill: fill, width: width, segments: segments)
    end

    def ellipse_at(center, rx, ry, color, fill: true, width: 1, segments: nil)
      points = Geometry.arc_points(center, rx, ry, segments: segments)
      points.pop # the closing duplicate
      if fill
        fan(center, points, color)
      else
        lines(points, color, closed: true, width: width)
      end
      self
    end

    # An arc from `from` to `to` degrees, counter-clockwise, y up.
    def arc(center, radius, from, to, color, width: 1, segments: nil)
      points = Geometry.arc_points(center, radius, radius, from: from, to: to, segments: segments)
      lines(points, color, width: width)
    end

    # A filled (or outlined) polygon; concave shapes are fine.
    def polygon(points, color, fill: true, width: 1)
      points = points.map { |p| Vector.coerce(p) }
      return lines(points, color, closed: true, width: width) unless fill

      indices = Geometry.triangulate(points).flatten
      return self if indices.empty?

      renderer.geometry(nil, vertices(points, color), indices)
      self
    end

    # Raw triangles: `vertices` is [[x, y, color], ...] in threes.
    def triangles(vertices)
      flat = vertices.flat_map do |(pos, color)|
        pos = Vector.coerce(pos)
        [pos.x, pos.y, *Color.coerce(color).to_a, 0, 0]
      end
      renderer.geometry(nil, flat, nil)
      self
    end

    # Text in SDL's built-in 8x8 font. `align` is :left, :center or :right
    # relative to `at`.
    def text(string, at:, color: :white, scale: 1, align: :left)
      string = string.to_s
      at = Vector.coerce(at)
      w = text_width(string, scale: scale)
      x = case align
          when :center then at.x - (w / 2.0)
          when :right then at.x - w
          else at.x
          end
      set_color(color)
      sx, sy = renderer.scale
      renderer.set_scale(sx * scale, sy * scale)
      renderer.debug_text(x / scale, at.y / scale, string)
      renderer.set_scale(sx, sy)
      self
    end

    def text_width(string, scale: 1) = string.to_s.length * FONT_SIZE * scale
    def text_height(scale: 1) = FONT_SIZE * scale

    # Uploads a Surface for fast drawing.
    def texture(surface)
      Texture.new(renderer.create_texture_from_surface(surface.native), renderer)
    end

    # A blank texture this canvas can draw into with #with_target.
    def target_texture(size)
      size = Vector.coerce(size)
      Texture.new(renderer.create_target_texture(size.x.round, size.y.round), renderer)
    end

    # Draws an image (Texture, or Surface uploaded for this call).
    #
    #   draw(tex, at: [10, 10])                   # natural size
    #   draw(tex, rect: [10, 10, 64, 64])         # scaled into a rect
    #   draw(tex, at: p, source: [0, 0, 16, 16])  # a sprite-sheet cell
    #   draw(tex, at: p, angle: 90, flip: :horizontal)
    def draw(image, at: nil, rect: nil, source: nil, angle: 0, center: nil, flip: :none, alpha: nil)
      texture = image.is_a?(Surface) ? texture(image) : image
      source = source && Rect.coerce(source)
      dest =
        if rect then Rect.coerce(rect)
        else
          size = source ? source.size : texture.size
          Rect.at(at || Vector::ZERO, size)
        end
      texture.alpha = alpha if alpha
      src = source ? source.to_a : [nil] * 4
      if angle.zero? && flip == :none
        renderer.render_texture(texture.native, *src, *dest.to_a)
      else
        c = center && Vector.coerce(center)
        renderer.render_texture_rotated(texture.native, *src, *dest.to_a, -angle.to_f, c&.x, c&.y, Surface::FLIP_MODES.fetch(flip))
      end
      texture.destroy if image.is_a?(Surface)
      self
    end

    # Restricts drawing to `rect` for the block.
    def clip(rect)
      renderer.set_clip_rect(*Rect.coerce(rect).round.to_a)
      yield self
    ensure
      renderer.set_clip_rect(nil, nil, nil, nil)
    end

    # Draws into `texture` for the block, then back to the canvas.
    def with_target(texture)
      renderer.render_target = texture.native
      yield self
    ensure
      renderer.render_target = nil
    end

    def blend_mode=(mode)
      renderer.blend_mode = Surface.blend_mode(mode)
    end

    # A device-independent resolution; SDL scales it to the output.
    def logical_size=(size)
      if size.nil?
        renderer.set_logical_presentation(0, 0, 0)
      else
        size = Vector.coerce(size)
        renderer.set_logical_presentation(size.x.round, size.y.round, PRESENTATION_MODES[:letterbox])
      end
    end

    def set_logical_size(size, mode: :letterbox)
      size = Vector.coerce(size)
      renderer.set_logical_presentation(size.x.round, size.y.round, PRESENTATION_MODES.fetch(mode))
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

    def set_color(color)
      renderer.set_draw_color(*Color.coerce(color).to_a)
    end

    def vertices(points, color)
      rgba = Color.coerce(color).to_a
      points.flat_map { |p| [p.x, p.y, *rgba, 0, 0] }
    end

    def fan(center, points, color)
      center = Vector.coerce(center)
      all = [center, *points]
      indices = (1..points.length).flat_map { |i| [0, i, i == points.length ? 1 : i + 1] }
      renderer.geometry(nil, vertices(all, color), indices)
    end
  end
end
