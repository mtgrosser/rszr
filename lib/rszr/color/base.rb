module Rszr
  module Color

    class Base
      attr_reader :alpha

      def rgba
        [red, green, blue, alpha]
      end

      def cmya
        [cyan, magenta, yellow, alpha]
      end

      def to_fill(*)
        Fill.new(color: self)
      end
    end

  end
end
