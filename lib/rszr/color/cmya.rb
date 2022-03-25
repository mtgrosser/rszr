module Rszr
  module Color

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

  end
end
