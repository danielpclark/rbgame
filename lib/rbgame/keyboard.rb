# frozen_string_literal: true

module Rbgame
  # The keyboard's state right now, outside the event stream. Keys are named
  # as in Key (`:left`, `:space`, `:a`).
  #
  #   Keyboard.pressed?(:left)
  #   Keyboard.pressed            # => [:left, :left_shift]
  #   Keyboard.shift?
  module Keyboard
    class << self
      def pressed?(key) = Native.key_pressed?(Native.scancode_from_key(Key.code(key)))

      # Symbols of every key currently held.
      def pressed = Native.pressed_scancodes.map { |scancode| Key.sym(Native.key_from_scancode(scancode)) }

      def modifiers = Native.mod_state
      def shift? = Key::Mod.shift?(modifiers)
      def ctrl? = Key::Mod.ctrl?(modifiers)
      def alt? = Key::Mod.alt?(modifiers)
    end
  end
end
