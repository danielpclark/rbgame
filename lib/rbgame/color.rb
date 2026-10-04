# frozen_string_literal: true

module Rbgame
  # An immutable RGBA colour with 8-bit channels.
  #
  #   Color.new(255, 128, 0)             # opaque orange
  #   Color.new(255, 128, 0, a: 128)     # half transparent
  #   Color["#ff8000"]                   # hex strings
  #   Color[:orange]                     # named colours
  #   Color[[255, 128, 0]]               # arrays
  #   Color::RED.with(a: 64)             # Data#with keeps the rest
  #   Color::RED.lerp(Color::BLUE, 0.5)
  #
  # Anything a drawing method takes as a colour goes through Color.coerce,
  # so all of the forms above work wherever a colour is expected.
  Color = Data.define(:r, :g, :b, :a) do
    include Comparable

    # Color.new(r, g, b), Color.new(r, g, b, a), Color.new(r, g, b, a: 128) or
    # keywords throughout. (Data's own `new` is on the singleton, so it is
    # wrapped by prepending rather than overridden.)
    singleton_class.prepend(Module.new do
      def new(*args, **kwargs)
        return super(**kwargs) if args.empty?

        r, g, b, a = args
        super(r: r, g: g, b: b, a: a || kwargs.fetch(:a, 255))
      end
    end)

    def initialize(r:, g:, b:, a: 255)
      super(r: self.class.channel(r, :r), g: self.class.channel(g, :g), b: self.class.channel(b, :b), a: self.class.channel(a, :a))
    end

    class << self
      # Turns whatever a caller passed as a colour into a Color.
      def coerce(value)
        case value
        when Color then value
        when Symbol then named(value)
        when String then parse(value)
        when Array then new(*value)
        when Integer then from_rgb_int(value)
        else
          raise TypeError, "cannot convert #{value.class} to #{name}"
        end
      end
      remove_method :[] # Data's own `[]` is `new`; ours coerces
      alias [] coerce

      def parse(string)
        if (m = Color::HEX.match(string))
          new(m[:r].hex, m[:g].hex, m[:b].hex, a: m[:a] ? m[:a].hex : 255)
        elsif (m = Color::SHORT_HEX.match(string))
          new((m[:r] * 2).hex, (m[:g] * 2).hex, (m[:b] * 2).hex)
        else
          named(string.downcase.tr(" -", "__").to_sym)
        end
      end

      def named(name)
        Color::NAMED.fetch(name.to_sym) { raise ArgumentError, "unknown colour name #{name.inspect}" }
      end

      # 0xRRGGBB
      def from_rgb_int(int)
        new((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
      end

      # Hue 0..360, saturation and value 0..1.
      def from_hsv(hue, saturation, value, a: 255)
        r, g, b = Color::HSV.to_rgb(hue, saturation, value)
        new((r * 255).round, (g * 255).round, (b * 255).round, a: a)
      end

      def channel(value, name)
        unless value.is_a?(Numeric) && value.between?(0, 255)
          raise ArgumentError, "#{name} must be between 0 and 255, got #{value.inspect}"
        end

        value.round
      end
    end

    def opaque? = a == 255
    def transparent? = a.zero?
    def to_a = [r, g, b, a]
    def rgb = [r, g, b]
    def to_hex = format("#%02x%02x%02x%s", r, g, b, opaque? ? "" : format("%02x", a))
    def to_s = to_hex
    def <=>(other) = other.is_a?(Color) ? to_a <=> other.to_a : nil

    # Linear interpolation towards `other`; t = 0 is self, t = 1 is other.
    def lerp(other, t)
      other = self.class.coerce(other)
      t = t.clamp(0.0, 1.0)
      self.class.new(*to_a.zip(other.to_a).map { |mine, theirs| mine + ((theirs - mine) * t) })
    end

    def lighten(amount = 0.2) = lerp(Color::WHITE.with(a: a), amount)
    def darken(amount = 0.2) = lerp(Color::BLACK.with(a: a), amount)
    def grayscale = self.class.new(*([(0.299 * r) + (0.587 * g) + (0.114 * b)] * 3), a: a)

    # Hue 0..360, saturation 0..1, value 0..1.
    def to_hsv = Color::HSV.from_rgb(r / 255.0, g / 255.0, b / 255.0)
  end

  class Color
    # The arithmetic of the HSV colour model, on 0..1 channels.
    module HSV
      module_function

      def to_rgb(hue, saturation, value)
        h = (hue % 360) / 60.0
        c = value * saturation
        x = c * (1 - ((h % 2) - 1).abs)
        m = value - c
        r, g, b = [[c, x, 0], [x, c, 0], [0, c, x], [0, x, c], [x, 0, c], [c, 0, x]][h.floor]
        [r + m, g + m, b + m]
      end

      def from_rgb(r, g, b)
        max = [r, g, b].max
        delta = max - [r, g, b].min
        hue =
          if delta.zero? then 0.0
          elsif max == r then 60 * (((g - b) / delta) % 6)
          elsif max == g then 60 * (((b - r) / delta) + 2)
          else 60 * (((r - g) / delta) + 4)
          end
        [hue, max.zero? ? 0.0 : delta / max, max]
      end
    end

    HEX = /\A#?(?<r>\h{2})(?<g>\h{2})(?<b>\h{2})(?<a>\h{2})?\z/
    SHORT_HEX = /\A#?(?<r>\h)(?<g>\h)(?<b>\h)\z/

    BLACK = Color.new(0, 0, 0)
    WHITE = Color.new(255, 255, 255)
    RED = Color.new(255, 0, 0)
    GREEN = Color.new(0, 255, 0)
    BLUE = Color.new(0, 0, 255)
    YELLOW = Color.new(255, 255, 0)
    CYAN = Color.new(0, 255, 255)
    MAGENTA = Color.new(255, 0, 255)
    ORANGE = Color.new(255, 128, 0)
    GRAY = Color.new(128, 128, 128)
    TRANSPARENT = Color.new(0, 0, 0, a: 0)

    # The 16-colour IBM EGA/CGA palette QBasic programs grew up with, by the
    # number COLOR took: EGA[14] is the yellow of a QBasic sun.
    EGA = [
      0x000000, 0x0000AA, 0x00AA00, 0x00AAAA, 0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA,
      0x555555, 0x5555FF, 0x55FF55, 0x55FFFF, 0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF
    ].map { |rgb| Color.from_rgb_int(rgb) }.freeze

    NAMED = {
      black: BLACK, white: WHITE, red: RED, green: GREEN, blue: BLUE, yellow: YELLOW,
      cyan: CYAN, magenta: MAGENTA, orange: ORANGE, gray: GRAY, grey: GRAY, transparent: TRANSPARENT,
      ega_black: EGA[0], ega_blue: EGA[1], ega_green: EGA[2], ega_cyan: EGA[3], ega_red: EGA[4],
      ega_magenta: EGA[5], ega_brown: EGA[6], ega_light_gray: EGA[7], ega_dark_gray: EGA[8],
      ega_light_blue: EGA[9], ega_light_green: EGA[10], ega_light_cyan: EGA[11], ega_light_red: EGA[12],
      ega_light_magenta: EGA[13], ega_yellow: EGA[14], ega_white: EGA[15]
    }.freeze
  end
end
