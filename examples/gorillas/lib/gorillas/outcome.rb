# frozen_string_literal: true

module Gorillas
  # How a throw ended.
  class Outcome < Data.define(:kind, :point, :victim)
    def self.missed(point) = new(kind: :missed, point: point, victim: nil)
    def self.building(point) = new(kind: :building, point: point, victim: nil)
    def self.gorilla(point, victim) = new(kind: :gorilla, point: point, victim: victim)

    def hit_gorilla? = kind == :gorilla
    def hit_building? = kind == :building
    def missed? = kind == :missed
    def explosion_radius = hit_gorilla? ? Explosion::GORILLA_RADIUS : Explosion::BUILDING_RADIUS
  end
end
