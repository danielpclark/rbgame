# frozen_string_literal: true

module Rbgame
  # The languages the user prefers, most preferred first, as the platform
  # reports them (LANGUAGE, then LANG, read when SDL starts, on Unix; the UI
  # languages on Windows; the system's preferred languages on macOS), for
  # picking a game's strings.
  #
  #   Locale.preferred          # => [Locale(language: "en", country: "US"), Locale("fr", nil)]
  #   Locale.first.language     # => "en"
  #   Locale.first.tag          # => "en-US"
  Locale = Data.define(:language, :country) do
    # The user's locales in order of preference; empty when the platform
    # does not say.
    def self.preferred = Native.preferred_locales.map { |language, country| new(language: language, country: country) }

    # The most preferred, or `Locale::DEFAULT`.
    def self.first = preferred.first || Locale::DEFAULT

    # The best match among the languages a game has, or `fallback`.
    def self.pick(available, fallback: available.first)
      available = available.map(&:to_s)
      preferred.each do |locale|
        return locale.tag if available.include?(locale.tag)
        return locale.language if available.include?(locale.language)
      end
      fallback
    end

    def tag = country ? "#{language}-#{country}" : language
    def to_s = tag
    def match?(other) = language == other.to_s.split(/[-_]/).first
  end
  Locale::DEFAULT = Locale.new(language: "en", country: nil)
end
