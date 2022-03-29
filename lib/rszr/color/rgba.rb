module Rszr
  module Color
    
    class << self
      def rgba(red, green, blue, alpha = 255)
        RGBA.new(red, green, blue, alpha)
      end

      def hex(str)
        str = str[1..-1] if str.start_with?('#')
        case str.size
        when 3, 4 then hex(str.chars.map { |c| c * 2 }.join)
        when 6 then hex("#{str}ff")
        when 8
          rgba(*str.scan(/../).map(&:hex))
        else
          raise ArgumentError, 'invalid color code'
        end
      end
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
        i = red.to_i << 24 | green.to_i << 16 | blue.to_i << 8 | self.alpha.to_i
        alpha ? i : i >> 8
      end

      def to_hex(alpha: true)
        "#%0#{alpha ? 8 : 6}x" % to_i(alpha: alpha)
      end

    end

  end
end
