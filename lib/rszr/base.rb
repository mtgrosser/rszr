module Rszr
  module Base
    
    def self.included(base)
      Rszr::Lib.delegate(base)
      Rszr::Lib.delegate(base.singleton_class)
      base.include(Lock)
      base.extend(Lock)
    end
    
    protected
    
    def handle
      @handle
    end
    
    def ptr
      @handle.ptr
    end
    
    private
    
    def assert_valid_keys(hsh, *valid_keys)
      if unknown_key = (hsh.keys - valid_keys).first
        raise ArgumentError.new("Unknown key: #{unknown_key.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
      end
    end
  end
end
