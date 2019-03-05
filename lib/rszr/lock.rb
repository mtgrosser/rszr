module Rszr
  @mutex = Mutex.new
  
  class << self
    
    def with_lock(&block) # :nodoc:
      mutex.synchronize(&block)
    end
    
    private
    
    def mutex
      @mutex
    end
  end
  
  module Lock # :nodoc:
    def with_lock(&block)
      Rszr.with_lock(&block)
    end
  end
  
end
