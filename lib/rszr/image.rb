module Rszr
  class Image
    include Base

    class << self
      
      alias_method :instantiate, :new
      protected :instantiate
      
      def new(width, height)
        ptr = with_lock { imlib_create_image(width, height) }
        raise Error, 'Could not instantiate image' if ptr.null?
        instantiate(ptr)
      end
            
      def load(path, options = {})
        path = path.to_s
        raise FileNotFound unless File.exist?(path)
        load_error = LoadError.new
        ptr = with_lock do
          imlib_set_cache_size(0)
          imlib_load_image_with_error_return(path, load_error.ptr)
        end
        raise load_error, load_error.message if ptr.null?
        return instantiate(ptr)
      end
      alias :open :load
      
      protected
      
      def finalize(ptr)
        with_lock do
          imlib_context_set_image(ptr)
          imlib_free_image
        end
      end
      
    end
    
    def initialize(ptr)
      @handle = Handle.new(self, ptr)
    end
    
    def width
      with_image { imlib_image_get_width }
    end
    
    def height
      with_image { imlib_image_get_height }
    end
    
    def dimensions
      [width, height]
    end
    
    def format
      str_ptr = with_image { imlib_image_format }
      return if str_ptr.null?
      str_ptr.to_s
    end
    
    def resize(*args)
      instantiate(create_resized_image(*args))
    end
    
    def resize!(*args)
      handle.replace!(create_resized_image(*args))
      self
    end
    
    def crop(*args)
      instantiate(create_cropped_image(*args))
    end
    
    def crop!(*args)
      handle.replace!(create_cropped_image(*args))
      self
    end
    
    def save(path, format = nil)
      with_image do
        format ||= format_from_filename(path) || 'jpg'
        imlib_image_set_format(format)
        save_error = SaveError.new
        imlib_save_image_with_error_return(path, save_error.ptr)
        raise save_error, save_error.message if save_error.error?
        true
      end
    end
    
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} width=#{width} height=#{height} format=#{format.inspect}>"
    end
    
    private
    
    # 0.5               0 < scale < 1
    # 400, 300          fit box
    # 400, :auto        fit width, auto height
    # :auto, 300        auto width, fit height
    # 400, 300, crop: :center_middle
    # 400, 300, background: rgba
    # 400, 300, aspect: false
    
    def create_resized_image(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      assert_valid_keys options, :crop, :background, :skew  #:extend, :width, :height, :max_width, :max_height, :box
      original_width, original_height = width, height
      x, y, = 0, 0
      if args.size == 1
        scale = args.first
        raise ArgumentError, "scale #{scale.inspect} out of range" unless scale > 0 && scale < 1
        new_width = original_width.to_f * scale
        new_height = original_height.to_f * scale
      elsif args.size == 2
        box_width, box_height = args
        if :auto == box_width && box_height.is_a?(Numeric)
          new_height = box_height
          new_width = box_height.to_f / original_height.to_f * original_width.to_f
        elsif box_width.is_a?(Numeric) && :auto == box_height
          new_width = box_width
          new_height = box_width.to_f / original_width.to_f * original_height.to_f
        elsif box_width.is_a?(Numeric) && box_height.is_a?(Numeric)
          if options[:skew]
            new_width, new_height = box_width, box_height
          elsif options[:crop]
            # TODO: calculate x, y offset if crop
          else
            scale = original_width.to_f / original_height.to_f
            box_scale = box_width.to_f / box_height.to_f
            if scale >= box_scale # wider
              new_width = box_width
              new_height = original_height.to_f * box_width.to_f / original_width.to_f
            else # narrower
              new_height = box_height
              new_width = original_width.to_f * box_height.to_f / original_height.to_f
            end
          end
        else
          raise ArgumentError, "unconclusive arguments #{args.inspect} #{options.inspect}"
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1..2)"
      end
      resized_ptr = with_image do
        imlib_context_set_anti_alias(1)
        imlib_create_cropped_scaled_image(x, y, imlib_image_get_width, imlib_image_get_height, new_width.round, new_height.round)
      end
      raise TransformationError, "error resizing image" if resized_ptr.null?
      resized_ptr
    end
    
    def create_cropped_image(x, y, width, height)
      cropped_ptr = with_image { imlib_create_cropped_image(x, y, width, height) }
      raise TransformationError, 'error cropping image' if cropped_ptr.null?
      cropped_ptr
    end
    
    def format_from_filename(path)
      File.extname(path)[1..-1]
    end
    
    def context_set_image
      imlib_context_set_image(ptr)
    end
    
    def with_image
      with_lock do
        context_set_image
        yield
      end
    end
    
    def instantiate(ptr)
      self.class.send(:instantiate, ptr)
    end
    
  end
end
