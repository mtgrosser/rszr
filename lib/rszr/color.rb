require_relative 'color/base'
require_relative 'color/rgba'
require_relative 'color/cmya'
require_relative 'color/point'
require_relative 'color/gradient'

module Rszr
  module Color

    Transparent = RGBA.new(0, 0, 0, 0)
    White = RGBA.new(255,255,255)
    Black = RGBA.new(0, 0, 0)

  end
end
