module Rszr
  module Color

    class Gradient
      attr_reader :points

      def initialize(*args)
        @points = []
        points = args.last.is_a?(Hash) ? args.pop.dup : {}
        args.each { |point| self << point }
        points.each { |pos, color| point(pos, color) }
        yield self if block_given?
      end

      def initialize_dup(other) # :nodoc:
        @points = other.points.map(&:dup)
      end

      def <<(position, red = nil, green = nil, blue= nil, alpha = 255)
        point = if red.is_a?(Point)
          red
        elsif red.is_a?(Color::Base)
          Point.new(position, red)
        elsif red.is_a?(String) && red.start_with?('#')
          Point.new(position, Color.hex(red))
        else
          Point.new(position, RGBA.new(red, green, blue, alpha))
        end
        points << point
        points.sort!
      end

      alias_method :point, :<<
      
      def to_fill(angle = 0)
        Fill.new(gradient: self, angle: angle)
      end

    end

  end
end
