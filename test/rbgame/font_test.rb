# frozen_string_literal: true

require "test_helper"

# Renders with a real font (DejaVu Sans Mono, vendored under test/fixtures
# with its license) and reads the pixels back.
class FontTest < Minitest::Test
  Font = Rbgame::Font
  Color = Rbgame::Color
  Vector = Rbgame::Vector

  FIXTURE = File.expand_path("../fixtures/DejaVuSansMono.ttf", __dir__)

  def setup
    @font = Font.load(FIXTURE, size: 20)
  end

  def test_loads_and_describes_the_font
    assert_equal 20.0, @font.size
    assert_equal "DejaVu Sans Mono", @font.family
    assert @font.fixed_width?
    assert @font.height > 15
    assert @font.line_height >= @font.height
    assert @font.ascent.positive?
    assert_raises(Rbgame::SDLError) { Font.load(File.join(__dir__, "missing.ttf"), size: 12) }
  end

  def test_measures_text
    one = @font.measure("W")
    four = @font.measure("WWWW")
    assert four.x.between?(one.x * 3, one.x * 4), "monospaced, give or take the side bearings"
    assert_equal one.y, four.y
    assert @font.measure("Hello, world", wrap: four.x).y > one.y, "wrapping adds lines"
  end

  def test_renders_text_to_a_surface
    rendered = @font.render("Hi", color: :yellow)
    assert_equal @font.measure("Hi"), rendered.size
    inked = rendered.bounds.to_a.then { |_, _, w, h| (0...w).to_a.product((0...h).to_a) }
                    .count { |x, y| rendered[x, y].a > 200 }
    assert inked > 20, "glyphs put ink on the surface"
    yellow = (0...rendered.width).to_a.product((0...rendered.height).to_a)
                                  .map { |x, y| rendered[x, y] }.find { |c| c.a > 200 }
    assert_equal [255, 255, 0], [yellow.r, yellow.g, yellow.b]
  end

  def test_styles_and_outline
    plain = @font.measure("Bold").x
    @font.style = %i[bold italic]
    assert_equal %i[bold italic], @font.style
    @font.style = :normal
    assert_equal [], @font.style
    assert_raises(ArgumentError) { @font.style = :sparkly }

    @font.outline = 2
    assert_equal 2, @font.outline
    assert @font.measure("Bold").x > plain, "an outline widens the text"
    @font.outline = 0
  end

  def test_size_can_change
    small = @font.measure("x").x
    @font.size = 40
    assert @font.measure("x").x > small
  end

  def test_canvas_draws_with_a_font
    screen = RbgameTest.screen
    screen.fill(:black)
    screen.text("Go!", at: [10, 10], font: @font, color: :white)
    screen.text("Go!", at: [190, 60], font: @font, color: :red, align: :right)
    screen.present
    shot = screen.to_surface
    width = @font.measure("Go!").x
    left = (10...(10 + width)).to_a.product((10...(10 + @font.height)).to_a).count { |x, y| shot[x, y] == Color::WHITE }
    right = ((190 - width)...190).to_a.product((60...(60 + @font.height)).to_a).count { |x, y| shot[x, y] == Color::RED }
    assert left > 20, "white text at the left"
    assert right > 20, "red text right-aligned to x=190"
    assert_equal width, screen.text_width("Go!", font: @font)
    assert_equal @font.height, screen.text_height(font: @font)
  end
end
