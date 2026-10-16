# frozen_string_literal: true

require "test_helper"

# The wind arrow and its strength on the left player's name line, drawn
# offscreen and read back: the arrow starts after the name however long it
# is and never touches it, the number follows the arrow, and the aim
# prompts' rows below are left alone.
class WindGaugeTest < Minitest::Test
  Field = Gorillas::Field
  View = Gorillas::View
  Palette = Gorillas::Palette
  GAP = View::WindGauge::GAP

  PROMPT_ROWS = 16..40 # Play's aim corner is [4, 16], two lines of 10

  def setup
    Rbgame.init
    @screen = Rbgame::Display.set_mode(Field::SIZE, title: "wind gauge test")
  end

  # Ten characters is the most the setup prompt takes; --names takes more.
  def test_the_arrow_follows_the_name_without_touching_it
    ["Maximilian", "Maximilian Longbottom"].product([0.3, 4.5, 9.9, -2.7, -9.9]).each do |name, speed|
      shot = draw(name, speed)
      name_end = name_end(name)
      left = name_end + GAP
      right = left + (speed.abs * View::WindGauge::PIXELS_PER_UNIT).round
      y = View::Scoreboard::NAME_Y + (@screen.text_height / 2)

      assert_blank shot, name_end...left, "#{name.inspect}, wind #{speed}: between the name and the arrow"
      (left..right).each { |x| assert_equal Palette::WIND, shot[x, y], "#{name.inspect}, wind #{speed}: arrow at x=#{x}" }
      assert_blank shot, (right + View::WindGauge::BARB + 1)...(right + GAP), "wind #{speed}: between the arrow and the number"
      assert_number shot, format("%.1f", speed.abs), at: right + GAP
    end
  end

  def test_the_number_is_the_strength_to_one_decimal_place
    assert_equal "9.9", View::WindGauge.new(Gorillas::Wind.new(speed: -9.9), after: "").label
    assert_equal "4.0", View::WindGauge.new(Gorillas::Wind.new(speed: 4), after: "").label
    assert_equal "0.3", View::WindGauge.new(Gorillas::Wind.new(speed: 0.3), after: "").label
  end

  def test_the_aim_prompt_rows_stay_clear
    shot = draw("Maximilian", -9.9)
    PROMPT_ROWS.each do |row|
      (0...Field::WIDTH).each { |x| assert_equal Palette::SKY, shot[x, row], "(#{x}, #{row})" }
    end
  end

  def test_no_wind_no_arrow_just_nought_point_nought
    shot = draw("Ruby", 0)
    number_at = name_end("Ruby") + GAP
    assert_blank shot, name_end("Ruby")...number_at, "no arrow"
    assert_number shot, "0.0", at: number_at
    assert_blank shot, (number_at + @screen.text_width("0.0"))...(Field::WIDTH / 2), "nothing after it"
  end

  private

  def name_end(name) = View::Scoreboard::MARGIN + @screen.text_width(name)

  def draw(name, speed)
    match = Gorillas::Match.new(names: [name, "Rust"])
    @screen.fill(Palette::SKY)
    View::Scoreboard.new(match).draw(@screen)
    View::WindGauge.new(Gorillas::Wind.new(speed: speed), after: name).draw(@screen)
    @screen.present
    @screen.to_surface
  end

  # Nothing drawn in these columns on the name line or above the prompts.
  def assert_blank(shot, columns, message)
    columns.each do |x|
      (0...PROMPT_ROWS.first).each { |row| assert_equal Palette::SKY, shot[x, row], "#{message}: (#{x}, #{row})" }
    end
  end

  # The number at `at` is pixel for pixel `text` drawn there on its own.
  def assert_number(shot, text, at:)
    @screen.fill(Palette::SKY)
    View::Typography.new(@screen).line(text, at: [at, View::Scoreboard::NAME_Y], color: Palette::WIND)
    @screen.present
    expected = @screen.to_surface
    (at...(at + @screen.text_width(text))).each do |x|
      (0...PROMPT_ROWS.first).each { |row| assert_equal expected[x, row], shot[x, row], "#{text.inspect} at (#{x}, #{row})" }
    end
  end
end
