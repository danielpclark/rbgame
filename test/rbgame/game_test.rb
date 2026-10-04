# frozen_string_literal: true

require "test_helper"

class GameTest < Minitest::Test
  class Counter < Rbgame::Game
    configure size: [64, 48], title: "counter", fps: 0

    attr_reader :log

    def setup = @log = [:setup]
    def update(dt) = @log << [:update, dt.class]
    def draw(screen) = (@log << :draw) && screen.fill(:red)
    def teardown = @log << :teardown
  end

  def test_hooks_run_in_order_and_the_loop_ends
    game = Counter.new.run(frames: 2)
    assert_equal :setup, game.log.first
    assert_equal :teardown, game.log.last
    assert_equal 2, game.log.count(:draw)
    assert_equal 2, game.frame
    refute game.running?
    refute Rbgame::Display.open?
  ensure
    RbgameTest.instance_variable_set(:@screen, nil)
  end

  def test_configuration_inherits_and_validates
    assert_equal [64, 48], Counter.configuration[:size]
    assert_equal 60, Rbgame::Game.configuration[:fps]
    assert_raises(ArgumentError) { Class.new(Rbgame::Game) { configure bogus: 1 } }
  end

  def test_quit_event_stops_the_game
    game = Counter.new
    game.on_event(Rbgame::Event::Quit.new(timestamp_ns: 0))
    refute game.running?
  end

  def test_screenshots
    Dir.mktmpdir do |dir|
      Counter.new.run(frames: 3, screenshots: dir, every: 2)
      assert_equal ["frame-00000.bmp", "frame-00002.bmp"], Dir.children(dir).sort
    end
  ensure
    RbgameTest.instance_variable_set(:@screen, nil)
  end
end
