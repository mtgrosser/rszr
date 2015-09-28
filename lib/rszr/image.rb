module Rszr
  class Image
    include Base

    class << self
      
      alias_method :instantiate, :new
      protected :instantiate
      
      def new(width, height)
        ptr = imlib_create_image(width, height)
        raise Error, 'Could not instantiate image' if ptr.null?
        instantiate(ptr)
      end
            
      def load(path, options = {})
        path = path.to_s
        raise FileNotFound unless File.exist?(path)
        ptr = imlib_load_image_without_cache(path)
        raise ImageLoadError if ptr.null?
        instantiate(ptr)
      end
      alias :open :load

      def finalize(ptr)
        imlib_context_set_image(ptr)
        imlib_free_image
      end
      
    end
    
    def initialize(ptr)
      @handle = Handle.new(self, ptr)
    end
    
    def width
      context_set_image
      imlib_image_get_width
    end
    
    def height
      context_set_image
      imlib_image_get_height
    end
    
    def dimensions
      [width, height]
    end
    
    def format
      context_set_image
      str_ptr = imlib_image_format
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
    
    def crop(x, y, width, height)
      context_set_image
      cropped_ptr = imlib_create_cropped_image(x, y, width, height)
      raise if cropped_ptr.null?
      instantiate(cropped_ptr)
    end
    
    def crop!(x, y, width, height)
      handle.replace!(crop(x, y, width, height).ptr)
    end
    
    def save(path, format = nil)
      context_set_image
      format ||= format_from_filename(path) || 'jpg'
      imlib_image_set_format(format)
      imlib_save_image(path)
      true
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
      context_set_image
      left, top = 0, 0
      if args.size == 1
        scale = args.first
        raise ArgumentError, "scale #{scale.inspect} out of range" unless scale > 0 && scale < 1
        new_width = (width.to_f * scale).to_i
        new_height = (height.to_f * scale).to_i
      elsif args.size == 2
        box_width, box_height = args
        if :auto == box_width && box_height.is_a?(Numeric)
          new_height = box_height
          new_width = (box_height.to_f / height.to_f * width).to_i
        elsif box_width.is_a?(Numeric) && :auto == box_height
          new_width = box_width
          new_height = (box_width.to_f / width.to_f * height).to_i
        elsif box_width.is_a?(Numeric) && box_height.is_a?(Numeric)
          if options[:skew]
            new_width, new_height = box_width, box_height
          elsif options[:crop]
            # TODO: calculate top, left offset if crop
          else
            scale = box_width.to_f / width.to_f
            scale = scale * box_height.to_f / (height.to_f * scale)
            new_width = (scale * width.to_f).to_i
            new_height = (scale * height.to_f).to_i
          end
        else
          raise ArgumentError, "unconclusive arguments #{args.inspect} #{options.inspect}"
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.size + 1} for 1..3)"
      end
      
      #new_width = options[:width] || imlib_image_get_width
      #new_height = options[:height] || imlib_image_get_height
      #if max_width = options[:max_width] and new_width > max_width
      #  scale  = max_width.to_f / new_width.to_f
      #  width  = max_width
      #  new_height = (scale * new_height).to_i
      #end
      #if max_height = options[:max_height] and new_height > max_height
      #  scale  = max_height.to_f / new_height.to_f
      #  new_height = max_height
      #  new_width  = (scale * new_width).to_i
      #end
      
      imlib_context_set_anti_alias(1)
      resized_ptr = imlib_create_cropped_scaled_image(left, top, imlib_image_get_width, imlib_image_get_height, new_width, new_height)
      raise TransformationError, "error resizing image" if resized_ptr.null?
      resized_ptr
    end
    
    def format_from_filename(path)
      File.extname(path)[1..-1]
    end
    
    def context_set_image
      imlib_context_set_image(ptr)
    end
    
    def instantiate(ptr)
      self.class.send(:instantiate, ptr)
    end
    
  end
end
