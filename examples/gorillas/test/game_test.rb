# frozen_string_literal: true

require "test_helper"

# The whole thing, headless: the game plays itself for a while and the
# frames it draws are not blank.
class GameTest < Minitest::Test
  def test_autoplay_runs_and_draws
    options = Gorillas::Options.new(autoplay: true, seed: 5, play_to: 1, sound: false, scale: 1, names: %w[A B])
    Dir.mktmpdir do |dir|
      game = Gorillas::Game.new(options)
      game.run(frames: 240, screenshots: dir, every: 120)
      frames = Dir.children(dir).sort
      assert_equal 2, frames.length
      last = Rbgame::Surface.load(File.join(dir, frames.last))
      colors = (0...640).step(16).flat_map { |x| (0...350).step(14).map { |y| last[x, y] } }.uniq
      assert_operator colors.length, :>, 3, "a frame of play should show more than sky"
      assert_includes colors, Gorillas::Palette::SKY
    end
  end
end
