module Rszr
  class Handle
    attr_reader :ptr, :klass
    
    def initialize(obj, ptr)
      @ptr = ptr
      raise ArgumentError, "#{obj.class.inspect} does not define the finalize class method" unless obj.class.respond_to?(:finalize, true)
      @klass = obj.class
      ObjectSpace.define_finalizer(obj, self)
    end
    
    def replace!(other_ptr)
      raise ArgumentError, "Cannot replace pointer with itself" if ptr == other_ptr
      finalize!
      @ptr = other_ptr
    end
    
    def finalize!(*args)
      puts "Finalizing #{args.inspect} #{ptr.inspect}"
      if !ptr.null? && klass
        puts "  calling #{args.inspect}"
        klass.send(:finalize, ptr)
        ptr = Fiddle::Pointer.new(0)
      else
        puts "  skipping #{args.inspect}"
      end
    end
    
    def release!
      replace! Fiddle::Pointer.new(0)
    end
    
    def call(object_id)
      finalize!(object_id)
    end
  end
end
