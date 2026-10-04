# frozen_string_literal: true

module Gorillas
  # The colours of GORILLA.BAS on an EGA screen, by the numbers COLOR took.
  module Palette
    EGA = Rbgame::Color::EGA

    SKY = EGA[1]
    SUN = EGA[14]
    BUILDINGS = [EGA[4], EGA[3], EGA[7]].freeze # red, cyan, light grey
    WINDOW_LIT = EGA[14]
    WINDOW_DARK = EGA[8]
    GORILLA = EGA[6]
    GORILLA_DETAIL = EGA[0]
    BANANA = EGA[14]
    EXPLOSION = EGA[4]
    EXPLOSION_CORE = EGA[14]
    TEXT = EGA[15]
    TEXT_DIM = EGA[7]
    WIND = EGA[12]
    FACE = EGA[0]
  end
end
