# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# SDL reads LANGUAGE (then LANG) on Unix once, when it starts, so each
# preference list is read in a fresh Ruby with the variables set for it.
# macOS has no locale backend in the translation yet (SDL asks Cocoa there),
# so it always reports an empty list; the environment tests skip on it.
class LocaleTest < Minitest::Test
  Locale = Rbgame::Locale

  def skip_without_an_environment_backend
    skip "SDL's locale backend for this platform does not read LANGUAGE" unless RUBY_PLATFORM.include?("linux")
  end

  def in_fresh_ruby(env, code)
    env = { "LANG" => "C", "LC_ALL" => nil, "LC_MESSAGES" => nil, "LANGUAGE" => nil }.merge(env)
    script = "require 'rbgame'; require 'json'; puts JSON.generate(#{code})"
    out, err, status = Open3.capture3(env, RbConfig.ruby, "-I", File.expand_path("../../lib", __dir__), "-e", script)
    assert status.success?, err
    JSON.parse(out.lines.last)
  end

  def test_reads_the_preference_list
    skip_without_an_environment_backend
    tags = in_fresh_ruby({ "LANGUAGE" => "fr_FR:de:en_US" }, "Rbgame::Locale.preferred.map(&:tag)")
    assert_equal %w[fr-FR de en-US], tags
    first = in_fresh_ruby({ "LANG" => "pt_BR.UTF-8" }, "Rbgame::Locale.first.to_h")
    assert_equal({ "language" => "pt", "country" => "BR" }, first)
  end

  def test_picks_the_best_language_a_game_has
    skip_without_an_environment_backend
    picks = in_fresh_ruby({ "LANGUAGE" => "pt_BR:es:en" }, <<~RUBY)
      [%w[en es de], %w[en pt-BR], %w[pt en], %w[en de], %w[de ja], %w[ja]].map { |available| Rbgame::Locale.pick(available) }
    RUBY
    assert_equal %w[es pt-BR pt en de ja], picks
  end

  def test_defaults_when_the_platform_does_not_say
    first = in_fresh_ruby({}, "[Rbgame::Locale.preferred.size, Rbgame::Locale.first.tag]")
    assert_equal [0, "en"], first, "no LANGUAGE or LANG set, or no backend, means no preference"
    assert_equal "en", Locale::DEFAULT.tag
    assert Locale::DEFAULT.match?("en-GB")
    refute Locale::DEFAULT.match?("fr")
    assert_equal :none, Locale.pick(%w[ja], fallback: :none) if Locale.preferred.empty?
    assert_equal "fr-CA", Locale.new(language: "fr", country: "CA").to_s
  end
end
