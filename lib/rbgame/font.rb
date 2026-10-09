# frozen_string_literal: true

module Rbgame
  # A TrueType or OpenType font through SDL_ttf (FreeType and HarfBuzz
  # translated, so every script HarfBuzz shapes). Renders text to Surfaces;
  # `Canvas#text` draws with one directly.
  #
  #   font = Font.load("DejaVuSans.ttf", size: 24)
  #   font.render("Score: 42", color: :yellow)        # => Surface
  #   font.measure("Score: 42")                        # => Vector
  #   screen.text("Ready?", at: screen.center, font: font, align: :center)
  #
  #   font.style = %i[bold italic]
  #   font.render("Long text wraps", wrap: 200)
  class Font
    STYLES = { bold: 1, italic: 2, underline: 4, strikethrough: 8 }.freeze

    attr_reader :native, :path

    # `size:` in points.
    def self.load(path, size: 16) = new(Native::Font.open(path.to_s, size.to_f), path: path.to_s)

    def initialize(native, path: nil)
      @native = native
      @path = path
    end

    def size = native.size

    def size=(points)
      native.size = points.to_f
    end

    def height = native.height
    def ascent = native.ascent
    def line_height = native.line_skip
    def family = native.family_name
    def fixed_width? = native.fixed_width?

    # :bold, :italic, :underline, :strikethrough, one or several; :normal clears.
    def style=(styles)
      native.style = Array(styles).sum { |style| style == :normal ? 0 : STYLES.fetch(style.to_sym) { raise ArgumentError, "unknown font style #{style.inspect}" } }
    end

    def style = STYLES.select { |_, bit| (native.style & bit) != 0 }.keys

    # Pixels of outline around each glyph; 0 for none.
    def outline=(pixels)
      native.outline = Integer(pixels)
    end

    def outline = native.outline

    # Width and height `string` takes in this font, as a Vector.
    def measure(string, wrap: nil)
      Vector.new(*native.measure(string.to_s, wrap&.round))
    end

    # The text as an anti-aliased RGBA Surface; `wrap:` is a width in pixels
    # to break lines at (0 breaks on newlines only).
    def render(string, color: :white, wrap: nil)
      color = Color.coerce(color)
      Surface.new(native.render(string.to_s, color.r, color.g, color.b, color.a, wrap&.round))
    end

    def inspect = "#<Rbgame::Font #{family.inspect} #{size}pt>"
  end
end
