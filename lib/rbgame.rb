# frozen_string_literal: true

require_relative "rbgame/version"
require_relative "rbgame/errors"
require_relative "rbgame/native"
require_relative "rbgame/color"
require_relative "rbgame/vector"
require_relative "rbgame/rect"
require_relative "rbgame/key"
require_relative "rbgame/mouse"
require_relative "rbgame/event"
require_relative "rbgame/events"
require_relative "rbgame/clock"
require_relative "rbgame/window"
require_relative "rbgame/surface"
require_relative "rbgame/texture"
require_relative "rbgame/geometry"
require_relative "rbgame/canvas"
require_relative "rbgame/display"
require_relative "rbgame/sound"
require_relative "rbgame/synth"
require_relative "rbgame/game"

# rbgame: games in Ruby on SDL, with SDL itself written in Rust and no C
# anywhere in the stack.
#
#   require "rbgame"
#
#   Rbgame.run(size: [640, 350], title: "Hello") do |screen|
#     screen.fill(:black)
#     screen.circle(screen.center, 40, :yellow)
#     screen.present
#     Rbgame::Events.each { |e| break if e in Rbgame::Event::Quit }
#   end
#
# or subclass Rbgame::Game.
module Rbgame
  SUBSYSTEMS = { audio: 0x10, video: 0x20, joystick: 0x200, haptic: 0x1000, gamepad: 0x2000, events: 0x4000 }.freeze

  # Video drivers that draw nowhere. When these are the only ones SDL was
  # built with, rbgame runs headless on `offscreen` and says so.
  HEADLESS_VIDEO_DRIVERS = %w[dummy offscreen].freeze

  VIDEO_DRIVER_HINT = "SDL_VIDEO_DRIVER"
  AUDIO_DRIVER_HINT = "SDL_AUDIO_DRIVER"

  class << self
    # Starts SDL's video (and audio) subsystems. Safe to call more than once.
    #
    # The video driver comes from `driver:`, then $RBGAME_VIDEO_DRIVER, then
    # SDL's own choice; when SDL has no driver that can open a window on
    # this machine, the `offscreen` driver is used so programs still run.
    def init(video: true, audio: true, driver: nil)
      init_video(driver) if video && !initialized?(:video)
      init_audio if audio && !initialized?(:audio)
      self
    end

    def initialized?(subsystem = :video)
      Native.was_init(SUBSYSTEMS.fetch(subsystem)) != 0
    end

    def quit
      Display.close if Display.open?
      Mixer.close
      Native.quit
      self
    end

    # init, open a display, yield it, quit afterwards whatever happens.
    def run(size: [640, 480], title: "rbgame", **display_options)
      init
      screen = Display.set_mode(size, title: title, **display_options)
      yield screen
    ensure
      quit
    end

    # True when the current video driver cannot show a window.
    def headless?
      HEADLESS_VIDEO_DRIVERS.include?(Native.current_video_driver)
    end

    def sdl_version = Native.sdl_version
    def platform = Native.platform
    def ticks = Clock.now
    def delay(seconds) = Clock.sleep(seconds)

    private

    def init_video(driver)
      driver ||= ENV["RBGAME_VIDEO_DRIVER"]
      driver ||= "offscreen" if (Native.video_drivers - HEADLESS_VIDEO_DRIVERS).empty?
      Native.set_hint(VIDEO_DRIVER_HINT, driver) if driver

      begin
        Native.init(SUBSYSTEMS[:video])
      rescue SDLError
        raise if driver

        Native.set_hint(VIDEO_DRIVER_HINT, "offscreen")
        Native.init(SUBSYSTEMS[:video])
      end
    end

    def init_audio
      driver = ENV["RBGAME_AUDIO_DRIVER"]
      Native.set_hint(AUDIO_DRIVER_HINT, driver) if driver
      Native.init(SUBSYSTEMS[:audio])
    rescue SDLError
      # No sound card, no driver: keep going without audio. Mixer notices.
      Native.set_hint(AUDIO_DRIVER_HINT, "dummy")
      begin
        Native.init(SUBSYSTEMS[:audio])
      rescue SDLError
        nil
      end
    end
  end
end
