# frozen_string_literal: true

module Gorillas
  # The city as pixels. GORILLA.BAS tested collisions with POINT (reading
  # the screen), and every explosion repainted its crater in the sky
  # colour; this does the same on a Surface, which also makes the craters
  # stay put between frames.
  class Terrain
    attr_reader :surface, :skyline

    def initialize(skyline)
      @skyline = skyline
      @surface = Rbgame::Surface.new(Field::SIZE).fill(Palette::SKY)
      @version = 0
      skyline.each { |building| paint(building) }
    end

    # Bumps whenever pixels change, so a cached texture knows to refresh.
    attr_reader :version

    # Reads the pixel from a Ruby-side copy of the buffer, refreshed after
    # each crater, so the autoplayer can probe thousands of points cheaply.
    def solid?(point)
      point = Rbgame::Vector.coerce(point).round
      return false unless Field::BOUNDS.contains?(point)

      offset = (point.y * surface.pitch) + (point.x * 4)
      pixels.byteslice(offset, 4) != sky_bytes
    end

    # Punches a crater; what was there is gone for good.
    def crater(center, radius)
      surface.fill_circle(center, radius, Palette::SKY)
      @version += 1
      self
    end

    private

    def pixels
      if @pixels_version != version
        @pixels = surface.pixels
        @pixels_version = version
      end
      @pixels
    end

    # The top-left pixel is always sky: buildings never reach it.
    def sky_bytes = @sky_bytes ||= surface.pixels.byteslice(0, 4)

    def paint(building)
      surface.fill(building.color, building.rect)
      building.window_rects.each do |rect, lit|
        surface.fill(lit ? Palette::WINDOW_LIT : Palette::WINDOW_DARK, rect)
      end
    end
  end
end
