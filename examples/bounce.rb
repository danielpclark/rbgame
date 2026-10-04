# frozen_string_literal: true

# A ball that keeps itself inside the screen. The README's example, as a
# program: `ruby -Ilib examples/bounce.rb`.

require "rbgame"

module Bounce
  # Where the ball is and where it is going. Moving it returns a new ball;
  # the one you had is unchanged.
  class Ball < Data.define(:center, :velocity, :radius)
    include Rbgame

    def after(seconds, within:)
      with(center: center + (velocity * seconds)).rebounding_off(within)
    end

    def draw_on(canvas) = canvas.circle(center, radius, :yellow)

    # A ball past an edge turns around on that axis.
    def rebounding_off(box)
      across = (box.left + radius)..(box.right - radius)
      down = (box.top + radius)..(box.bottom - radius)
      with(velocity: Vector.new(across.cover?(center.x) ? velocity.x : -velocity.x,
                                down.cover?(center.y) ? velocity.y : -velocity.y))
    end
  end

  class Game < Rbgame::Game
    include Rbgame

    configure size: [640, 350], title: "Bounce", fps: 60

    def setup
      @ball = Ball.new(center: screen.center, velocity: Vector.polar(30, 180), radius: 12)
    end

    def update(seconds) = @ball = @ball.after(seconds, within: screen.bounds)

    def draw(screen)
      screen.fill(Color::EGA[1])
      @ball.draw_on(screen)
      screen.text("Esc to quit", at: [8, 8])
    end

    def on_event(event)
      case event
      in Event::KeyDown[sym: :escape] then stop
      else super
      end
    end
  end
end

Bounce::Game.run if $PROGRAM_NAME == __FILE__
