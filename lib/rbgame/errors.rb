# frozen_string_literal: true

module Rbgame
  # Everything rbgame raises on its own is an Rbgame::Error, so a caller can
  # rescue the library as a whole.
  class Error < StandardError; end

  # A failure reported by SDL itself, with SDL's message.
  class SDLError < Error; end

  # Something used in the wrong order: a window after its destruction, the
  # display before Rbgame.init, and so on.
  class StateError < Error; end

  # The compiled extension could not be loaded.
  class NativeLoadError < Error; end
end
