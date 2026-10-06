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

  def test_save_and_load_png
    Dir.mktmpdir do |dir|
      path = File.join(dir, "pic.png")
      surface = Surface.new(3, 2).fill(:black)
      surface[1, 1] = Color.new(10, 20, 30, 128)
      surface.save(path)
      assert_equal "\x89PNG".b, File.binread(path, 4)
      loaded = Surface.load(path)
      assert_equal Rbgame::Vector[3, 2], loaded.size
      assert_equal Color.new(10, 20, 30, 128), loaded[1, 1], "PNG keeps the alpha channel"
    end
  end

  def test_saves_and_loads_the_formats_games_use
    Dir.mktmpdir do |dir|
      surface = Surface.new(5, 3).fill(:black)
      surface[2, 1] = Color::YELLOW
      %w[gif tga bmp jpg].each do |extension|
        path = File.join(dir, "pic.#{extension}")
        surface.save(path)
        loaded = Surface.load(path)
        assert_equal Rbgame::Vector[5, 3], loaded.size, extension
        assert_in_delta 255, loaded[2, 1].r, 8, "#{extension} keeps the pixel (JPEG within its loss)"
        assert_in_delta 0, loaded[0, 0].r, 8, extension
      end
      assert_raises(Rbgame::SDLError) { surface.save(File.join(dir, "pic.xyz")) }
    end
  end

  def test_rasterizes_svg
    Dir.mktmpdir do |dir|
      path = File.join(dir, "dot.svg")
      File.write(path, '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8"><rect width="8" height="8" fill="#0000ff"/></svg>')
      loaded = Surface.load(path)
      assert_equal Rbgame::Vector[8, 8], loaded.size
      assert_equal Color::BLUE, loaded[4, 4]
    end
  end

  def test_load_tells_formats_apart_by_content
    Dir.mktmpdir do |dir|
      path = File.join(dir, "actually-a-bmp.png")
      Surface.new(2, 2).fill(:green).save(File.join(dir, "pic.bmp"))
      File.rename(File.join(dir, "pic.bmp"), path)
      assert_equal Color::GREEN, Surface.load(path)[0, 0]
      assert_raises(Rbgame::SDLError) { Surface.load(File.join(dir, "missing.png")) }
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
