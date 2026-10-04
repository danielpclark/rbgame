# frozen_string_literal: true

require "rbgame"

# Gorillas, after GORILLA.BAS: two gorillas on a skyline hurl exploding
# bananas at each other. Written in Ruby on rbgame, drawn to an SDL window
# instead of a text-mode screen.
#
# The model (Match, Round and its phases, Skyline, Terrain, Shot, Flight)
# knows nothing of pixels or keys; the views draw it and the scenes feed it
# input through a controller, a Keyboard or an Autopilot.
module Gorillas
end

%w[
  field palette building skyline terrain wind shot flight banana gorilla sun explosion outcome
  player match round round/phase autoplayer prompt questionnaire typist
  controllers/keyboard controllers/autopilot jukebox
  view/typography view/gorilla_sprite view/sun_sprite view/banana_sprite view/explosion_sprite
  view/wind_gauge view/city_view view/field_view view/scoreboard
  scenes/base scenes/intro scenes/setup scenes/play scenes/game_over game
].each { |file| require_relative "gorillas/#{file}" }
