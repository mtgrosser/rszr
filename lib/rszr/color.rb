module Rszr
  module Color

    class Base
      attr_reader :alpha
    end

    class RGBA < Base
      attr_reader :red, :green, :blue

      def initialize(red, green, blue, alpha = 255)
        if red < 0 || red > 255 || green < 0 || green > 255 || blue < 0 || blue > 255 || alpha < 0 || alpha > 255
          raise ArgumentError, 'color out of range'
        end
        @red, @green, @blue, @alpha = red, green, blue, alpha
      end

      def cyan
        255 - red
      end

      def magenta
        255 - green
      end

      def yellow
        255 - blue
      end

      def to_i(alpha: true)
        i = red.to_i << 24 | green.to_i << 16 | blue.to_i << 8 | alpha.to_i
        alpha ? i : i >> 8
      end

      def to_hex(rgb: false)
        "%0#{rgb ? 6 : 8}x" % to_i(rgb: rgb)
      end
    end

    class CMYA < Base
      attr_reader :cyan, :magenta, :yellow

      def initialize(cyan, magenta, yellow, alpha = 255)
        if cyan < 0 || cyan > 255 || magenta < 0 || magenta > 255 || yellow < 0 || yellow > 255 || alpha < 0 || alpha > 255
          raise ArgumentError, 'color out of range'
        end
        @cyan, @magenta, @yellow = cyan, magenta, yellow
      end

      def red
        255 - cyan
      end

      def green
        255 - magenta
      end

      def blue
        255 - yellow
      end

    end

    Transparent = RGBA.new(0, 0, 0, 0)
    White = RGBA.new(255,255,255)
    Black = RGBA.new(0, 0, 0)

  end
end
