# frozen_string_literal: true

module Rbgame
  # The frame loop as a class to subclass: a template method per phase.
  #
  #   class Pong < Rbgame::Game
  #     configure size: [640, 480], title: "Pong", fps: 60
  #
  #     def setup        = @ball = Vector[320, 240]
  #     def update(dt)   = @ball += @velocity * dt
  #     def draw(screen) = screen.circle(@ball, 6, :white)
  #
  #     def on_event(event)
  #       case event
  #       in Event::KeyDown[sym: :escape] then stop
  #       else super
  #       end
  #     end
  #   end
  #
  #   Pong.run
  #
  # The default on_event stops the game on Quit and on the window's close
  # button; call super from an override to keep that.
  class Game
    DEFAULTS = { size: [640, 480], title: "rbgame", fps: 60, logical: nil, resizable: false }.freeze

    class << self
      def configure(**options)
        unknown = options.keys - DEFAULTS.keys
        raise ArgumentError, "unknown game options: #{unknown.join(", ")}" unless unknown.empty?

        @configuration = configuration.merge(options)
      end

      def configuration
        @configuration ||= (superclass.respond_to?(:configuration) ? superclass.configuration : DEFAULTS).dup
      end

      # Builds the game and runs it to completion.
      def run(**options) = new.run(**options)
    end

    attr_reader :screen, :clock, :frame

    def initialize
      @running = false
      @frame = 0
    end

    def configuration = self.class.configuration

    # Opens the display and loops until #stop. `frames:` ends the loop after
    # that many frames (for tests and headless recordings); `screenshots:`
    # saves a BMP of every frame (or every `every`th) into a directory.
    def run(frames: nil, screenshots: nil, every: 1)
      Rbgame.init
      @screen = Display.set_mode(configuration[:size], title: configuration[:title],
                                 logical: configuration[:logical], resizable: configuration[:resizable])
      @clock = Clock.new
      @running = true
      setup

      while @running
        Events.each { |event| on_event(event) }
        break unless @running

        update(clock.tick(configuration[:fps]))
        draw(screen)
        screen.present
        screen.screenshot(File.join(screenshots, format("frame-%05d.bmp", @frame))) if screenshots && (@frame % every).zero?
        @frame += 1
        stop if frames && @frame >= frames
      end

      teardown
      self
    ensure
      Display.close if Display.open?
    end

    def running? = @running
    def stop = @running = false
    alias quit! stop

    # Hooks, in call order.
    def setup; end
    def update(dt); end
    def draw(screen); end
    def teardown; end

    def on_event(event)
      case event
      when Event::Quit then stop
      when Event::Window then stop if event.close_requested?
      end
    end
  end
end
