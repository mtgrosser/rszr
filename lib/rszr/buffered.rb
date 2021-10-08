module Rszr
  module Buffered
    def self.included(base)
      base.extend self
    end
    
    private
    
    def with_tempfile(data = nil)
      #ext = File.extname(name)
      result = nil
      #Tempfile.create([File.basename(name, ext), ext], tmpdir) do |file|
      #  result = yield(file)
      #end
      Tempfile.new(encoding: 'BINARY') do |file|
        if data
          file.binwrite data
          file.fsync
        end
        result = yield(file)
      end
      result
    end
    
  end
end
