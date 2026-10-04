# frozen_string_literal: true

module Rbgame
  # A set of named SDL modes. The API takes Symbols (`:blend`, `:nearest`,
  # `:horizontal`); a Mode turns them into the integers the extension wants
  # and names the integers coming back. Unknown names fail loudly, listing
  # the choices.
  class Mode
    attr_reader :what

    def initialize(what, codes)
      @what = what
      @codes = codes.freeze
    end

    # The code for a name; an Integer is taken as a code already.
    def code(name)
      return name if name.is_a?(Integer)

      @codes.fetch(name.to_sym) do
        raise ArgumentError, "unknown #{what} #{name.inspect}; expected one of #{@codes.keys.join(", ")}"
      end
    end

    def name(code) = @codes.key(code) || code
    def names = @codes.keys
  end

  BLEND_MODES = Mode.new("blend mode", none: 0, blend: 1, add: 2, mod: 4, mul: 8)
  SCALE_MODES = Mode.new("scale mode", nearest: 0, linear: 1, pixel_art: 2)
  FLIP_MODES = Mode.new("flip mode", none: 0, horizontal: 1, vertical: 2)
  PRESENTATION_MODES = Mode.new("presentation mode", disabled: 0, stretch: 1, letterbox: 2, overscan: 3, integer_scale: 4)
end
