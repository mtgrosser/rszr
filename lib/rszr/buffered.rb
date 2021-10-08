module Rszr
  module Buffered
    def self.included(base)
      base.extend Buffered
    end
    
    private
    
    def with_tempfile(format, data = nil)
      raise ArgumentError, 'format is required' unless format
      result = nil
      Tempfile.create(['rszr-buffer', ".#{format}"], encoding: 'BINARY') do |file|
        if data
          file.binmode
          file << data
          file.fsync
          file.rewind
        end
        result = yield(file)
      end
      result
    end
    
  end
end
