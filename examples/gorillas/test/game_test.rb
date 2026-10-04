# frozen_string_literal: true

require "test_helper"

# The whole thing, headless: the game plays itself for a while and the
# frames it draws are the game, not just sky.
class GameTest < Minitest::Test
  Palette = Gorillas::Palette

  def test_autoplay_runs_and_draws
    options = Gorillas::Options.new(autoplay: true, seed: 5, play_to: 1, sound: false, scale: 1, names: %w[A B])
    Dir.mktmpdir do |dir|
      game = Gorillas::Game.new(options)
      game.run(frames: 240, screenshots: dir, every: 30)
      frames = Dir.children(dir).sort.map { |name| Rbgame::Surface.load(File.join(dir, name)) }
      assert_equal 8, frames.length

      # Scenes change on the clock, not the frame count, so only the first
      # frame is certain: the title card, with its sun and gorillas.
      title_card = colors_in(frames.first)
      assert_includes title_card, Palette::SKY
      assert_includes title_card, Palette::SUN
      assert_includes title_card, Palette::GORILLA
      assert_includes title_card, Palette::TEXT

      # Every frame is drawn on the sky, whatever scene it caught.
      frames.each { |frame| assert_includes colors_in(frame), Palette::SKY }
    end
  end

  private

  # The colours on a coarse grid over the frame.
  def colors_in(frame)
    (0...640).step(8).flat_map { |x| (0...350).step(7).map { |y| frame[x, y] } }.uniq
  end
end
