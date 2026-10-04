# frozen_string_literal: true

require "test_helper"

# The README's programs, run for real, so the README stays true.
class ExamplesTest < Minitest::Test
  EXAMPLES = File.expand_path("../../examples", __dir__)

  def test_bounce_runs_and_the_ball_stays_on_screen
    load File.join(EXAMPLES, "bounce.rb")
    game = Bounce::Game.new.run(frames: 120)
    ball = game.instance_variable_get(:@ball)
    assert Rbgame::Rect.new(0, 0, 640, 350).contains?(ball.center)
    assert_equal 120, game.frame
  ensure
    RbgameTest.instance_variable_set(:@screen, nil)
  end

  def test_the_hand_rolled_loop_leaves_on_quit
    frames = 0
    Rbgame.run(size: [320, 200], title: "Hello") do |screen|
      clock = Rbgame::Clock.new
      Rbgame::Events.push_quit
      until Rbgame::Events.any?(Rbgame::Event::Quit)
        screen.fill(:black).circle(screen.center, 40, :yellow).present
        clock.tick(60)
        frames += 1
      end
    end
    assert_equal 0, frames, "a queued Quit ends the loop before the first frame"
  ensure
    RbgameTest.instance_variable_set(:@screen, nil)
  end
end
