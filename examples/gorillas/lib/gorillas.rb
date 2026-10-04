# frozen_string_literal: true

require "rbgame"

# Gorillas, after GORILLA.BAS: two gorillas on a skyline hurl exploding
# bananas at each other. Written in Ruby on rbgame, drawn to an SDL window
# instead of a text-mode screen.
module Gorillas
end

require_relative "gorillas/palette"
require_relative "gorillas/screen"
require_relative "gorillas/building"
require_relative "gorillas/skyline"
require_relative "gorillas/terrain"
require_relative "gorillas/wind"
require_relative "gorillas/shot"
require_relative "gorillas/gorilla"
require_relative "gorillas/sun"
require_relative "gorillas/banana"
require_relative "gorillas/explosion"
require_relative "gorillas/player"
require_relative "gorillas/match"
require_relative "gorillas/round"
require_relative "gorillas/prompt"
require_relative "gorillas/sounds"
require_relative "gorillas/autoplayer"
require_relative "gorillas/scenes/base"
require_relative "gorillas/scenes/intro"
require_relative "gorillas/scenes/setup"
require_relative "gorillas/scenes/play"
require_relative "gorillas/scenes/game_over"
require_relative "gorillas/game"
