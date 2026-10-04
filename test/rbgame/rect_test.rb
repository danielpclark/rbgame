# frozen_string_literal: true

require "test_helper"

class RectTest < Minitest::Test
  Rect = Rbgame::Rect
  Vector = Rbgame::Vector

  def setup
    @rect = Rect.new(10, 20, 100, 50)
  end

  def test_edges_and_points
    assert_equal 10, @rect.left
    assert_equal 110, @rect.right
    assert_equal 20, @rect.top
    assert_equal 70, @rect.bottom
    assert_equal Vector[60.0, 45.0], @rect.center
    assert_equal Vector[110, 70], @rect.bottomright
    assert_equal Vector[60.0, 20], @rect.midtop
    assert_equal Vector[100, 50], @rect.size
  end

  def test_coerce
    assert_equal @rect, Rect[[10, 20, 100, 50]]
    assert_equal @rect, Rect[10, 20, 100, 50]
    assert_equal @rect, Rect[[[10, 20], [100, 50]]]
    assert_equal @rect, Rect.at([10, 20], [100, 50])
    assert_equal @rect, Rect.from_center([60, 45], [100, 50])
    assert_equal Rect[1, 2, 3, 4], Rect.bounding([[1, 2], [4, 6], [2, 3]])
  end

  def test_moves_return_new_rects
    moved = @rect.move(5, -5)
    assert_equal Rect[15, 15, 100, 50], moved
    assert_equal Rect[10, 20, 100, 50], @rect
    assert_equal Rect[0, 0, 100, 50], @rect.at([0, 0])
    assert_equal Rect[-50.0, -25.0, 100, 50], @rect.centered_at([0, 0])
    assert_equal Rect[5.0, 15.0, 110, 60], @rect.inflate(10)
    assert_equal Rect[10, 20, 100, 50].area, @rect.scale_by(1).area
  end

  def test_containment_and_collision
    assert @rect.contains?([10, 20])
    refute @rect.contains?([110, 20]) # right edge is exclusive
    assert @rect.contains?(Rect[20, 30, 10, 10])
    assert @rect.collide?(Rect[100, 60, 50, 50])
    refute @rect.collide?(Rect[110, 70, 5, 5])
  end

  def test_clip_union_clamp
    assert_equal Rect[100, 60, 10, 10], @rect.clip(Rect[100, 60, 50, 50])
    assert @rect.clip(Rect[500, 500, 5, 5]).empty?
    assert_equal Rect[10, 20, 140, 90], @rect.union(Rect[100, 60, 50, 50])
    assert_equal Rect[0, 0, 100, 50], @rect.clamp(Rect[0, 0, 100, 50])
    assert_equal Rect[-45.0, -20.0, 100, 50], @rect.clamp(Rect[0, 0, 10, 10])
  end

  def test_normalize
    assert_equal Rect[0, 0, 10, 10], Rect[10, 10, -10, -10].normalize
  end
end
