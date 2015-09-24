module Rszr
  module Base
    
    protected
    
    def ptr
      @ptr
    end
    
    private
    
    def assert_valid_keys(hsh, *valid_keys)
      if unknown_key = (hsh.keys - valid_keys).first
        raise ArgumentError.new("Unknown key: #{unknown_key.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
      end
    end
  end
end
