module Rszr
  module Color

    class RGBA
      attr_reader :red, :green, :blue, :alpha

      def initialize(red, green, blue, alpha = 255)
        if red < 0 || red > 255 || green < 0 || green > 255 || blue < 0 || blue > 255 || alpha < 0 || alpha > 255
          raise ArgumentError, 'color out of range'
        end
        @red, @green, @blue, @alpha = red, green, blue, alpha
      end
      
      def to_i(rgb: false)
        i = red.to_i << 24 | green.to_i << 16 | blue.to_i << 8 | alpha.to_i
        rgb ? i >> 8 : i
      end
      
      def to_hex(rgb: false)
        "%0#{rgb ? 6 : 8}x" % to_i(rgb: rgb)
      end
    end

  end
end
