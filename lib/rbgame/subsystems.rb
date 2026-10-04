# frozen_string_literal: true

module Rbgame
  # Which SDL video driver to ask for, decided from what was requested, the
  # environment, and what this build of SDL has. A pure decision, so it can
  # be tested without SDL.
  module VideoDriver
    ENV_VAR = "RBGAME_VIDEO_DRIVER"

    # Drivers that draw nowhere. When these are all SDL has, rbgame runs
    # headless on `offscreen` rather than failing to start.
    HEADLESS = %w[dummy offscreen].freeze
    FALLBACK = "offscreen"

    module_function

    # The driver to set as SDL's hint, or nil to let SDL choose.
    def choose(requested:, available:, env: ENV)
      requested || env[ENV_VAR] || (FALLBACK if (available - HEADLESS).empty?)
    end

    def headless?(driver) = HEADLESS.include?(driver)
  end

  # SDL's subsystems, started on demand and at most once.
  module Subsystems
    FLAGS = { audio: 0x10, video: 0x20, joystick: 0x200, haptic: 0x1000, gamepad: 0x2000, events: 0x4000 }.freeze

    # One subsystem: knows its flag and the hint that picks its driver.
    class Subsystem
      attr_reader :name

      def initialize(name, hint:)
        @name = name
        @hint = hint
      end

      def started? = Native.was_init(FLAGS.fetch(name)) != 0

      def start(driver: nil)
        return self if started?

        Native.set_hint(@hint, driver) if driver
        Native.init(FLAGS.fetch(name))
        self
      end

      def stop = tap { Native.quit_subsystem(FLAGS.fetch(name)) }
    end

    # Video: the driver is chosen by VideoDriver; if SDL still cannot start
    # one, fall back to offscreen so programs run everywhere.
    class Video < Subsystem
      def initialize = super(:video, hint: "SDL_VIDEO_DRIVER")

      def start(driver: nil)
        return self if started?

        chosen = VideoDriver.choose(requested: driver, available: Native.video_drivers)
        super(driver: chosen)
      rescue SDLError
        raise if chosen

        super(driver: VideoDriver::FALLBACK)
      end

      def driver = Native.current_video_driver
      def headless? = VideoDriver.headless?(driver)
    end

    # Audio: no sound card and no driver is not an error, just silence; the
    # dummy driver keeps the subsystem up so Sound and Mixer still work.
    class Audio < Subsystem
      ENV_VAR = "RBGAME_AUDIO_DRIVER"

      def initialize = super(:audio, hint: "SDL_AUDIO_DRIVER")

      def start(driver: ENV[ENV_VAR])
        super
      rescue SDLError
        begin
          super(driver: "dummy")
        rescue SDLError
          self
        end
      end
    end

    class << self
      def video = @video ||= Video.new
      def audio = @audio ||= Audio.new
      def [](name) = { video: video, audio: audio }.fetch(name) { Subsystem.new(name, hint: nil) }
    end
  end
end
