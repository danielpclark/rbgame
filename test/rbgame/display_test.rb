# frozen_string_literal: true

require "test_helper"

# Draws on an offscreen screen and reads the pixels back.
class DisplayTest < Minitest::Test
  Color = Rbgame::Color
  Vector = Rbgame::Vector

  def setup
    @screen = RbgameTest.screen
  end

  def test_setup_on_the_requested_driver
    assert Rbgame.initialized?(:video)
    assert_equal RbgameTest.video_driver, Rbgame::Display.driver
    assert_equal RbgameTest.headless?, Rbgame.headless?
    assert_includes Rbgame::Display.drivers, "offscreen"
    assert_equal "software", @screen.driver
    assert_equal Vector[200, 120], @screen.size
    assert_equal "rbgame tests", @screen.title
  end

  def test_primitives_land_where_drawn
    @screen.fill(:black)
    @screen.fill_rect([10, 10, 20, 20], :red)
    @screen.circle([100, 60], 15, :yellow)
    @screen.stroke_rect([150, 10, 30, 30], :white)
    @screen.line([0, 119], [199, 119], :cyan)
    @screen.polygon([[50, 100], [70, 100], [60, 80]], :green)
    @screen.present

    shot = @screen.to_surface
    assert_equal Color::BLACK, shot[0, 0]
    assert_equal Color::RED, shot[15, 15]
    assert_equal Color::BLACK, shot[30, 30]
    assert_equal Color::YELLOW, shot[100, 60]
    assert_equal Color::BLACK, shot[100, 40]
    assert_equal Color::WHITE, shot[150, 20]
    assert_equal Color::BLACK, shot[165, 25]
    assert_equal Color::CYAN, shot[100, 119]
    assert_equal Color::GREEN, shot[60, 95]
  end

  def test_text_is_drawn_and_measured
    @screen.fill(:black)
    @screen.text("HI", at: [8, 8], color: :white)
    assert_equal 16, @screen.text_width("HI")
    assert_equal 32, @screen.text_width("HI", scale: 2)
    shot = @screen.to_surface
    lit = (8...24).sum { |x| (8...16).count { |y| shot[x, y] == Color::WHITE } }
    assert lit.positive?, "text drew nothing"
  end

  def test_textures_draw_and_rotate
    sprite = Rbgame::Surface.new(4, 4).fill(:magenta)
    texture = @screen.texture(sprite)
    assert_equal Vector[4.0, 4.0], texture.size
    @screen.fill(:black)
    @screen.draw(texture, at: [20, 20])
    @screen.draw(texture, rect: [40, 40, 8, 8], angle: 90)
    shot = @screen.to_surface
    assert_equal Color::MAGENTA, shot[21, 21]
    assert_equal Color::MAGENTA, shot[44, 44]
    texture.destroy
    assert texture.destroyed?
  end

  def test_surfaces_draw_like_textures
    sprite = Rbgame::Surface.new(4, 4).fill(:cyan)
    @screen.fill(:black)
    @screen.draw(sprite, at: [10, 10])
    @screen.draw(sprite, rect: [30, 30, 8, 8], angle: 180, alpha: 255)
    @screen.draw(sprite, at: [50, 50], source: [0, 0, 2, 2])
    shot = @screen.to_surface
    assert_equal Color::CYAN, shot[11, 11]
    assert_equal Color::CYAN, shot[34, 34]
    assert_equal Color::CYAN, shot[51, 51]
    assert_equal Color::BLACK, shot[53, 53], "only the 2x2 source cell was drawn"
  end

  def test_clip_restricts_drawing
    @screen.fill(:black)
    @screen.clip([0, 0, 50, 50]) { |canvas| canvas.fill_rect([0, 0, 200, 120], :blue) }
    shot = @screen.to_surface
    assert_equal Color::BLUE, shot[10, 10]
    assert_equal Color::BLACK, shot[100, 100]
  end

  def test_render_to_texture
    target = @screen.target_texture([16, 16])
    @screen.with_target(target) { |canvas| canvas.fill(:green) }
    @screen.fill(:black)
    @screen.draw(target, at: [0, 0])
    assert_equal Color::GREEN, @screen.to_surface[5, 5]
  end

  def test_screenshot_writes_a_bmp
    Dir.mktmpdir do |dir|
      path = File.join(dir, "shot.bmp")
      @screen.fill(:white).screenshot(path)
      assert_equal Color::WHITE, Rbgame::Surface.load(path)[0, 0]
    end
  end

  def test_logical_size_scales_output
    Rbgame::Display.set_mode([200, 120], title: "logical", logical: [100, 60])
    screen = Rbgame::Display.screen
    assert_equal Vector[100, 60], screen.size
    assert_equal Vector[200, 120], screen.output_size
    screen.fill(:black).fill_rect([0, 0, 10, 10], :red)
    shot = screen.to_surface
    assert_equal Color::RED, shot[15, 15], "a 10x10 logical rect covers 20x20 output pixels"
    assert_equal Vector[5.0, 5.0], screen.from_window([10, 10])
  ensure
    RbgameTest.instance_variable_set(:@screen, nil)
  end
end
