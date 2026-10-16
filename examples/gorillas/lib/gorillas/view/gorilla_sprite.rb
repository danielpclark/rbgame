# frozen_string_literal: true

module Gorillas
  module View
    # A Gorilla drawn pixel by pixel over its 30x31 bounds: brown fur, a
    # tan face and ears, a black brow, eyes, nostrils and chest, fists on
    # its hips or raised. The gorilla is symmetric, so only the left half
    # is drawn here and the right half is its mirror; a half has its arm
    # down or up, and the poses pair them. Field pixels are taller than
    # wide, so the art is squashed the way the field stretches it back.
    class GorillaSprite
      COLORS = { "B" => Palette::GORILLA, "f" => Palette::GORILLA_FACE, "#" => Palette::GORILLA_DETAIL }.freeze

      ARM_DOWN = %w[
        ............BBB
        ...........BBBB
        ..........fB###
        ..........fBfff
        ..........fB##f
        ...........BBff
        ...........Bf#f
        ...........Bfff
        .......BBBBBBBB
        .......BBBBBBff
        ...BBBBBBBBBBBB
        ..BBBBBBBBBBBB#
        .BBBBBBBBBBBBB#
        BBBBBBBBBBBBB##
        BBBBBBB.BBBB##B
        BBBBBB..BBB##BB
        BBBBBB...BBBBBB
        BBBBBB....BBBBB
        .BBBBBB...BBBBB
        .BBBBBBB..BBBBB
        ..BBBBBB.BBBBBB
        ..BBBBB.BBBBBBB
        .......BBBBBBBB
        ......BBBBBBB..
        ......BBBBBB...
        .....BBBBBB....
        .....BBBBBB....
        .....BBBBBB....
        ....BBBBBBB....
        ...BBBBBBBB....
        ..BBBBBBBBBB...
      ].freeze

      ARM_UP = %w[
        ..BBB.......BBB
        .BBBBB.....BBBB
        .BBBBB....fB###
        .BBBBB....fBfff
        ..BBBB....fB##f
        ..BBBB.....BBff
        ..BBBBB....Bf#f
        ..BBBBBB...Bfff
        ...BBBBBBBBBBBB
        ....BBBBBBBBBff
        .....BBBBBBBBBB
        .....BBBBBBBBB#
        ......BBBBBBBB#
        .......BBBBBB##
        ........BBBB##B
        ........BBB##BB
        .........BBBBBB
        ..........BBBBB
        ..........BBBBB
        ..........BBBBB
        .........BBBBBB
        ........BBBBBBB
        .......BBBBBBBB
        ......BBBBBBB..
        ......BBBBBB...
        .....BBBBBB....
        .....BBBBBB....
        .....BBBBBB....
        ....BBBBBBB....
        ...BBBBBBBB....
        ..BBBBBBBBBB...
      ].freeze

      # The left and right halves of each pose.
      ARMS = {
        at_ease: [ARM_DOWN, ARM_DOWN], left_up: [ARM_UP, ARM_DOWN],
        right_up: [ARM_DOWN, ARM_UP], both_up: [ARM_UP, ARM_UP]
      }.freeze

      # Each pose's rows, the right half mirrored onto the left.
      BITMAPS = ARMS.transform_values { |(left, right)| left.zip(right).map { |l, r| l + r.reverse }.freeze }.freeze

      def initialize(gorilla)
        @gorilla = gorilla
      end

      def draw(canvas)
        bounds = @gorilla.bounds
        BITMAPS.fetch(@gorilla.pose).each_with_index do |row, dy|
          x = 0
          row.scan(/((.)\2*)/) do |run, char|
            canvas.fill_rect([bounds.x + x, bounds.y + dy, run.length, 1], COLORS[char]) if COLORS.key?(char)
            x += run.length
          end
        end
      end
    end
  end
end
