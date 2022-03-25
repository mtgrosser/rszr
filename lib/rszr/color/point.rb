module Rszr
  module Color

    class Point
      attr_reader :position, :color

      class << self
        def prgba(position, red, green, blue, alpha = 255)
          new(position, RGBA.new(red, green, blue, alpha))
        end
      end

      def initialize(position, color)
        raise ArgumentError, 'position must be within 0..1' unless (0..1).cover?(position)
        raise ArgumentError, 'color must be a Rszr::Color::Base' unless color.is_a?(Rszr::Color::Base)
        @position, @color = position, color
      end

      def <=>(other)
        position <=> other.position
      end

      def prgba
        [position, *color.rgba]
      end
    end

  end
end
