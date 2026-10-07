# frozen_string_literal: true

module Rbgame
  # The system clipboard's text. Without a platform clipboard (headless,
  # say) SDL keeps the text itself, so it round-trips everywhere.
  #
  #   Clipboard.text = "high score: 42"
  #   Clipboard.text          # => "high score: 42"
  #   Clipboard.text?         # => true
  module Clipboard
    class << self
      def text = Native.clipboard_text

      def text=(string)
        Native.set_clipboard_text(string.to_s)
      end

      def text? = Native.clipboard_has_text?
      def clear = tap { Native.clear_clipboard }

      # An image on the clipboard as a Surface, or nil.
      def image = Native.clipboard_image&.then { |surface| Surface.new(surface) }
    end
  end
end
