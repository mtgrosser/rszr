require 'rbconfig'
require 'pathname'
require 'tempfile'

require 'rszr/rszr'
require 'rszr/version'
require 'rszr/identification'
require 'rszr/buffered'
require 'rszr/image'

module Rszr
  class << self
    @@autorotate = nil
    
    def autorotate
      @@autorotate
    end
  
    def autorotate=(value)
      @@autorotate = !!value
    end
  end
end
