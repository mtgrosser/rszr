module Rszr
  class Fill
    attr_reader :color, :gradient, :angle

    def initialize(color: nil, gradient: nil, angle: 0)
      if gradient
        @gradient = gradient
        @angle = angle || 0
      elsif color
        @color = color
      else
        raise ArgumentError, 'incomplete fill definition'
      end
    end

    def to_fill(*)
      self
    end

  end
end
