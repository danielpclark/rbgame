# frozen_string_literal: true

module Rbgame
  # Keys by name. rbgame refers to keys with Symbols (:escape, :space, :a,
  # :left_shift, :keypad_1, :f5) derived from SDL's key names, so no table of
  # constants has to be memorised:
  #
  #   event.key?(:escape)
  #   Key.pressed?(:left)             # current state, outside the event stream
  #   Key.code(:return)               # the SDL keycode, if ever needed
  module Key
    # Bits of KeyDown#modifiers (SDL_Keymod).
    module Mod
      NONE = 0x0000
      LSHIFT = 0x0001
      RSHIFT = 0x0002
      LCTRL = 0x0040
      RCTRL = 0x0080
      LALT = 0x0100
      RALT = 0x0200
      LGUI = 0x0400
      RGUI = 0x0800
      NUM = 0x1000
      CAPS = 0x2000
      SHIFT = LSHIFT | RSHIFT
      CTRL = LCTRL | RCTRL
      ALT = LALT | RALT
      GUI = LGUI | RGUI
    end

    # SDL spells some names in ways a Symbol can't carry well; these are the
    # Ruby spellings for them. Every other key is its SDL name, downcased,
    # with spaces as underscores.
    ALIASES = {
      escape: "Escape", esc: "Escape", return: "Return", enter: "Return", space: "Space",
      backspace: "Backspace", tab: "Tab", delete: "Delete", insert: "Insert",
      left: "Left", right: "Right", up: "Up", down: "Down",
      home: "Home", end: "End", page_up: "PageUp", page_down: "PageDown",
      left_shift: "Left Shift", right_shift: "Right Shift", left_ctrl: "Left Ctrl",
      right_ctrl: "Right Ctrl", left_alt: "Left Alt", right_alt: "Right Alt",
      caps_lock: "CapsLock", plus: "+", minus: "-", equals: "=", comma: ",", period: ".",
      slash: "/", backslash: "\\", semicolon: ";", apostrophe: "'", grave: "`",
      left_bracket: "[", right_bracket: "]"
    }.freeze

    class << self
      # The SDL keycode of a key named by Symbol (or an Integer passed through).
      def code(key)
        return key if key.is_a?(Integer)

        @codes ||= {}
        @codes[key.to_sym] ||= begin
          code = Native.key_from_name(sdl_name(key))
          raise ArgumentError, "unknown key #{key.inspect}" if code.zero?

          code
        end
      end

      def sdl_name(key)
        key = key.to_sym
        ALIASES.fetch(key) do
          name = key.to_s
          if name.start_with?("keypad_") then "Keypad #{name.delete_prefix("keypad_").capitalize}"
          elsif name.length == 1 then name.upcase
          else name.split("_").map(&:capitalize).join(" ")
          end
        end
      end

      # The Symbol for an SDL keycode: :escape, :a, :"1", :left_shift ...
      def sym(code)
        @syms ||= {}
        @syms[code] ||= symbolize(Native.key_name(code))
      end

      def symbolize(sdl_name)
        return :unknown if sdl_name.empty?

        ALIASES.key(sdl_name) || sdl_name.downcase.tr(" ", "_").to_sym
      end

      # Is the key held down right now?
      def pressed?(key)
        Native.key_pressed?(Native.scancode_from_key(code(key)))
      end

      # Symbols of every key currently held.
      def pressed
        Native.pressed_scancodes.map { |scancode| sym(Native.key_from_scancode(scancode)) }
      end

      def modifiers = Native.mod_state
      def shift? = (modifiers & Mod::SHIFT) != 0
      def ctrl? = (modifiers & Mod::CTRL) != 0
      def alt? = (modifiers & Mod::ALT) != 0
    end
  end
end
