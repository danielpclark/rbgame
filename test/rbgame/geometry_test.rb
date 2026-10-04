# frozen_string_literal: true

require "test_helper"

class GeometryTest < Minitest::Test
  Geometry = Rbgame::Geometry
  Vector = Rbgame::Vector

  def test_triangulates_a_convex_polygon
    square = [[0, 0], [10, 0], [10, 10], [0, 10]]
    assert_equal 2, Geometry.triangulate(square).length
  end

  def test_triangulates_a_concave_polygon_without_covering_the_notch
    w_shape = [[0, 0], [40, 0], [30, 30], [20, 10], [10, 30]].map { |p| Vector[*p] }
    triangles = Geometry.triangulate(w_shape)
    assert_equal 3, triangles.length
    notch = Vector[20, 20]
    covered = triangles.any? do |i, j, k|
      Geometry.inside_triangle?(notch, w_shape[i], w_shape[j], w_shape[k])
    end
    refute covered, "the notch between the Ws legs must stay empty"
  end

  def test_winding_does_not_matter
    clockwise = [[0, 0], [0, 10], [10, 10], [10, 0]]
    assert_equal 2, Geometry.triangulate(clockwise).length
  end

  def test_degenerate_input
    assert_empty Geometry.triangulate([[0, 0], [1, 1]])
  end

  def test_arc_points
    points = Geometry.arc_points([0, 0], 10, from: 0, to: 90, segments: 4)
    assert_equal Vector[10, 0], points.first.round
    assert_equal Vector[0, -10], points.last.round
    assert_equal 2, points.length
  end

  def test_thick_line_corners
    corners = Geometry.thick_line([0, 0], [10, 0], 4)
    assert_equal [[0, 2], [10, 2], [10, -2], [0, -2]], corners.map { |c| c.round.to_a }
  end
end
