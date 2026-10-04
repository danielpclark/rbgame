# frozen_string_literal: true

module Rbgame
  # A CPU-side RGBA image. Surfaces are for pixel work (collision masks,
  # procedurally built sprites, screenshots); to draw them quickly every frame
  # turn them into a Texture with Canvas#texture.
  #
  #   mask = Surface.new([64, 64])
  #   mask.fill(:black)
  #   mask.fill_circle([32, 32], 20, :white)
  #   mask[10, 10]            # => Color
  #   mask.save("mask.png")
  #   Surface.load("sprite.png")
  class Surface
    attr_reader :native

    # Loads a PNG, JPEG or BMP file, told apart by its contents.
    def self.load(path) = new(Native.load_image(path.to_s))

    # Surface.new([w, h]) or Surface.new(w, h); also wraps a Native::Surface.
    def initialize(size_or_native, height = nil)
      @native =
        if size_or_native.is_a?(Native::Surface)
          size_or_native
        else
          size = height ? Vector.new(size_or_native, height) : Vector.coerce(size_or_native)
          Native.create_surface(size.x.round, size.y.round)
        end
    end

    def width = native.width
    def height = native.height
    def size = Vector.new(width, height)
    def bounds = Rect.new(0, 0, width, height)
    def pitch = native.pitch
    def format = native.format_name

    # Writes a PNG, or a BMP when the name ends in .bmp.
    def save(path)
      path = path.to_s
      File.extname(path).casecmp?(".bmp") ? native.save_bmp(path) : native.save_png(path)
      self
    end

    # Fills `rect` (or everything) with a colour.
    def fill(color, rect = nil)
      color = Color.coerce(color)
      rect = rect && Rect.coerce(rect).round
      native.fill_rect(*(rect ? rect.to_a : [nil] * 4), *color.to_a)
      self
    end

    # A filled circle drawn as horizontal spans, so it works on any surface.
    def fill_circle(center, radius, color)
      center = Vector.coerce(center)
      color = Color.coerce(color)
      r = radius.to_f
      (-r.floor..r.floor).each do |dy|
        half = Math.sqrt((r * r) - (dy * dy))
        x0 = (center.x - half).round
        x1 = (center.x + half).round
        native.fill_rect(x0, (center.y + dy).round, x1 - x0 + 1, 1, *color.to_a)
      end
      self
    end

    def fill_rect(rect, color) = fill(color, rect)

    # The colour at a point; nil outside the surface.
    def [](x, y = nil)
      pos = (y.nil? ? Vector.coerce(x) : Vector.new(x, y)).round
      return nil unless bounds.contains?(pos)

      Color.new(*native.get_pixel(pos.x, pos.y))
    end
    alias get []

    def []=(x, y, color = nil)
      if color.nil?
        color, pos = y, Vector.coerce(x)
      else
        pos = Vector.new(x, y)
      end
      pos = pos.round
      return unless bounds.contains?(pos)

      native.set_pixel(pos.x, pos.y, *Color.coerce(color).to_a)
    end
    alias set []=

    # Copies `source` (or `source_rect` of it) onto this surface at `at`.
    def blit(source, at: Vector::ZERO, source_rect: nil)
      at = Vector.coerce(at).round
      src = source_rect && Rect.coerce(source_rect).round
      native.blit(source.native, *(src ? src.to_a : [nil] * 4), at.x, at.y)
      self
    end

    # Copies `source` scaled into `rect`.
    def blit_scaled(source, rect, source_rect: nil, mode: :nearest)
      rect = Rect.coerce(rect).round
      src = source_rect && Rect.coerce(source_rect).round
      native.blit_scaled(source.native, *(src ? src.to_a : [nil] * 4), *rect.to_a, SCALE_MODES.code(mode))
      self
    end

    # Pixels of this colour become transparent when blitted; nil clears it.
    def color_key=(color)
      if color.nil?
        native.set_color_key(nil, 0, 0)
      else
        native.set_color_key(*Color.coerce(color).rgb)
      end
    end

    def alpha=(alpha)
      native.alpha_mod = alpha
    end

    def alpha = native.alpha_mod

    def blend_mode=(mode)
      native.blend_mode = BLEND_MODES.code(mode)
    end

    def blend_mode = BLEND_MODES.name(native.blend_mode)

    def color_mod=(color)
      native.set_color_mod(*Color.coerce(color).rgb)
    end

    def clip=(rect)
      rect = rect && Rect.coerce(rect).round
      native.set_clip_rect(*(rect ? rect.to_a : [nil] * 4))
    end

    def dup = Surface.new(native.duplicate)
    alias duplicate dup

    def scaled(size, mode: :nearest)
      size = Vector.coerce(size)
      Surface.new(native.scale(size.x.round, size.y.round, SCALE_MODES.code(mode)))
    end

    # A copy rotated `degrees` counter-clockwise (the same direction as
    # Canvas#draw's angle); the copy grows to fit.
    def rotated(degrees) = Surface.new(native.rotate(-degrees.to_f))

    def flip!(direction)
      native.flip(FLIP_MODES.code(direction))
      self
    end

    def flipped(direction) = dup.flip!(direction)

    # Uploads this surface to `canvas` for the block and frees it after, so
    # a Surface can be drawn wherever a Texture can (see Canvas#draw).
    def with_texture(canvas)
      texture = canvas.texture(self)
      yield texture
    ensure
      texture&.destroy
    end

    # Raw RGBA bytes, `pitch` per row.
    def pixels = native.pixels
    def pixels=(bytes)
      native.pixels = bytes
    end

    def inspect = "#<Rbgame::Surface #{width}x#{height}>"
  end
end
