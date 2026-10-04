# frozen_string_literal: true

module Rbgame
  # The mouse, outside the event stream.
  module Mouse
    BUTTONS = { left: 1, middle: 2, right: 3, x1: 4, x2: 5 }.freeze

    class << self
      def position = Vector.new(*Native.mouse_position)

      def pressed?(button)
        bit = 1 << (BUTTONS.fetch(button) { raise ArgumentError, "unknown mouse button #{button.inspect}" } - 1)
        (Native.mouse_buttons & bit) != 0
      end

      def visible=(visible)
        Native.cursor_visible = visible
      end

      def visible? = Native.cursor_visible?
      def button_name(number) = BUTTONS.key(number) || :"button_#{number}"
    end
  end
end
