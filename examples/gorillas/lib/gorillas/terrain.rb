# frozen_string_literal: true

module Gorillas
  # The city as pixels. GORILLA.BAS tested collisions with POINT (reading
  # the screen) and every explosion repainted its crater in the sky
  # colour; this does the same on a Surface, so craters persist.
  class Terrain
    attr_reader :surface, :version

    def initialize(skyline)
      @surface = Rbgame::Surface.new(Field::SIZE).fill(Palette::SKY)
      @version = 0
      skyline.each { |building| paint(building) }
    end

    # Reads a Ruby-side copy of the pixels, refreshed after each crater, so
    # the autoplayer can probe thousands of points cheaply.
    def solid?(point)
      point = Rbgame::Vector.coerce(point).round
      return false unless Field.contains?(point)

      pixels.byteslice((point.y * surface.pitch) + (point.x * 4), 4) != sky_bytes
    end

    # Punches a crater; what was there is gone for good. The hole is a
    # CIRCLE's ellipse, round on the stretched field.
    def crater(center, radius)
      center = Rbgame::Vector.coerce(center)
      ry = radius * Field::ASPECT
      (-ry.ceil..ry.ceil).each do |dy|
        next if dy.abs > ry

        half = radius * Math.sqrt(1 - ((dy / ry)**2))
        surface.fill(Palette::SKY, [center.x - half, center.y + dy, (half * 2) + 1, 1])
      end
      @version += 1
      self
    end

    private

    def pixels
      return @pixels if @pixels_version == version

      @pixels_version = version
      @pixels = surface.pixels
    end

    # The top-left pixel is always sky: buildings never reach it.
    def sky_bytes = @sky_bytes ||= surface.pixels.byteslice(0, 4)

    def paint(building)
      surface.fill(building.color, building.rect)
      building.windows.each { |window| surface.fill(window.color, window.rect) }
    end
  end
end
