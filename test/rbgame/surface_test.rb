# frozen_string_literal: true

require "test_helper"

class SurfaceTest < Minitest::Test
  Surface = Rbgame::Surface
  Color = Rbgame::Color

  def test_fill_and_read_pixels
    surface = Surface.new([4, 3])
    surface.fill(:red)
    assert_equal Color::RED, surface[0, 0]
    assert_equal Color::RED, surface[[3, 2]]
    assert_nil surface[4, 0]
    surface[1, 1] = :blue
    assert_equal Color::BLUE, surface[1, 1]
    assert_equal Rbgame::Vector[4, 3], surface.size
  end

  def test_fill_rect_and_circle
    surface = Surface.new(10, 10)
    surface.fill(:black)
    surface.fill(:white, [2, 2, 3, 3])
    assert_equal Color::WHITE, surface[2, 2]
    assert_equal Color::WHITE, surface[4, 4]
    assert_equal Color::BLACK, surface[5, 5]
    surface.fill_circle([5, 5], 3, :green)
    assert_equal Color::GREEN, surface[5, 5]
    assert_equal Color::GREEN, surface[8, 5]
    assert_equal Color::BLACK, surface[8, 8]
  end

  def test_blit
    src = Surface.new(2, 2).fill(:yellow)
    dst = Surface.new(4, 4).fill(:black)
    dst.blit(src, at: [1, 1])
    assert_equal Color::YELLOW, dst[1, 1]
    assert_equal Color::YELLOW, dst[2, 2]
    assert_equal Color::BLACK, dst[3, 3]
  end

  def test_blit_rejects_self
    surface = Surface.new(2, 2)
    assert_raises(ArgumentError) { surface.blit(surface) }
  end

  def test_scaled_rotated_flipped_copies
    surface = Surface.new(2, 2).fill(:black)
    surface[0, 0] = :white
    assert_equal Rbgame::Vector[4, 4], surface.scaled([4, 4]).size
    assert_equal Color::WHITE, surface.scaled([4, 4])[0, 0]
    assert_equal Color::WHITE, surface.flipped(:horizontal)[1, 0]
    assert_equal Color::WHITE, surface.rotated(90)[0, 1]
    assert_equal Color::WHITE, surface[0, 0], "the original is untouched"
  end

  def test_save_and_load_bmp
    Dir.mktmpdir do |dir|
      path = File.join(dir, "pic.bmp")
      surface = Surface.new(3, 2).fill(:cyan)
      surface.save(path)
      assert File.exist?(path)
      loaded = Surface.load(path)
      assert_equal Rbgame::Vector[3, 2], loaded.size
      assert_equal Color::CYAN, loaded[2, 1]
    end
  end

  def test_raw_pixels
    surface = Surface.new(1, 1).fill(:red)
    bytes = surface.pixels
    assert_equal 4, bytes.bytesize
    assert_equal Encoding::BINARY, bytes.encoding
    surface.pixels = [0, 0, 255, 255].pack("C*")
    assert_equal Color::BLUE, surface[0, 0]
    assert_raises(ArgumentError) { surface.pixels = "x" }
  end
end
