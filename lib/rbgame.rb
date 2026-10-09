# frozen_string_literal: true

%w[
  version errors native mode color vector rect key keyboard mouse event events clock
  window surface texture geometry canvas canvas/shapes canvas/text canvas/images display gamepad camera clipboard animation font
  sound mixer music synth subsystems frame_recorder game
].each { |file| require_relative "rbgame/#{file}" }

# rbgame: games in Ruby on SDL, with SDL itself written in Rust and no C
# anywhere in the stack.
#
#   require "rbgame"
#
#   Rbgame.run(size: [640, 350], title: "Hello") do |screen|
#     clock = Rbgame::Clock.new
#     until Rbgame::Events.any?(Rbgame::Event::Quit)
#       screen.fill(:black).circle(screen.center, 40, :yellow).present
#       clock.tick(60)
#     end
#   end
#
# or subclass Rbgame::Game.
module Rbgame
  class << self
    # Starts SDL's video (and audio) subsystems. Safe to call more than once.
    #
    # The video driver comes from `driver:`, then $RBGAME_VIDEO_DRIVER, then
    # SDL's own choice; when SDL has no driver that can open a window on
    # this machine, the `offscreen` driver is used so programs still run.
    def init(video: true, audio: true, driver: nil)
      Subsystems.video.start(driver: driver) if video
      Subsystems.audio.start if audio
      self
    end

    def initialized?(subsystem = :video) = Subsystems[subsystem].started?

    def quit
      Display.close if Display.open?
      Mixer.close
      Native.quit
      self
    end

    # init, open a display, yield it, quit afterwards whatever happens.
    def run(size: [640, 480], title: "rbgame", **display_options)
      init
      yield Display.set_mode(size, title: title, **display_options)
    ensure
      quit
    end

    # True when the current video driver cannot show a window.
    def headless? = Subsystems.video.headless?

    def sdl_version = Native.sdl_version
    def platform = Native.platform
    def ticks = Clock.now
    def delay(seconds) = Clock.sleep(seconds)
  end
end
