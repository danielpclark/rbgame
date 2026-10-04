# frozen_string_literal: true

require "test_helper"

class MatchTest < Minitest::Test
  def test_scoring_and_winning
    match = GorillasTest.match(play_to: 2, names: %w[Ann Bob])
    refute match.over?
    match.score!(match.left)
    assert_equal match.right, match.opening_player, "the loser throws first"
    match.score!(match.left)
    assert match.over?
    assert_equal "Ann", match.winner.name
  end

  def test_validation
    assert_raises(ArgumentError) { GorillasTest.match(play_to: 0) }
    assert_raises(ArgumentError) { GorillasTest.match(gravity: -1) }
  end
end
