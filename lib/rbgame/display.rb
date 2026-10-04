# frozen_string_literal: true

module Rbgame
  # The screen: a Canvas backed by a Window.
  #
  #   screen = Display.set_mode([640, 350], title: "Gorillas")
  #   screen.fill(:black)
  #   screen.present
  class Screen < Canvas
    attr_reader :window

    def initialize(window, renderer)
      super(renderer)
      @window = window
    end

    # Shows what was drawn since the last present.
    def present = tap { renderer.present }
    alias flip present

    def title = window.title
    def title=(title)
      window.title = title
    end

    def window_size = window.size

    def vsync=(on)
      renderer.vsync = on == true ? 1 : (on || 0)
    end

    def driver = renderer.name
    def inspect = "#<Rbgame::Screen #{size} on #{window.inspect}>"
  end

  module Display
    class << self
      # Opens the window and returns the Screen. `logical:` sets a
      # resolution independent of the window size (letterboxed).
      def set_mode(size = [640, 480], title: "rbgame", logical: nil, vsync: nil, driver: nil, **window_options)
        Rbgame.init unless Rbgame.initialized?(:video)
        close if @screen

        window = Window.new(title: title, size: size, **window_options)
        renderer = Native.create_renderer(window.native, driver)
        @screen = Screen.new(window, renderer)
        @screen.logical_size = logical if logical
        @screen.vsync = vsync unless vsync.nil?
        @screen
      end
      alias open set_mode

      def screen
        @screen or raise StateError, "no display: call Rbgame::Display.set_mode first"
      end

      def open? = !@screen.nil?

      def close
        @screen&.window&.destroy
        @screen = nil
      end

      # Names of the video drivers this build of SDL has.
      def drivers = Native.video_drivers
      def driver = Native.current_video_driver
    end
  end
end
