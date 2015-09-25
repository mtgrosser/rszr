module Rszr
  class Image
    include Base

    class << self
      
      protected :new
      
      def load(path, options = {})
        raise unless File.exist?(path)
        ptr = imlib_load_image_without_cache(path)
        raise if ptr.null?
        new(ptr)
      end
      
      private
      
      def finalizer(ptr)
        Proc.new do
          imlib_context_set_image(ptr)
          imlib_free_image
        end
      end
    end
    
    def initialize(ptr)
      @ptr = ptr
      ObjectSpace.define_finalizer(self, self.class.send(:finalizer, ptr))
    end
    
    def width
      context_set_image
      imlib_image_get_width
    end
    
    def height
      context_set_image
      imlib_image_get_height
    end
    
    def resize(options = {})
      assert_valid_keys options, :width, :height, :max_width, :max_height
      context_set_image
      new_width = options[:width] || imlib_image_get_width
      new_height = options[:height] || imlib_image_get_height

      if max_width = options[:max_width]
        if new_width > max_width
          scale  = max_width.to_f / new_width.to_f
          width  = max_width
          new_height = (scale * new_height).to_i
        end
      end
      if max_height = options[:max_height]
        if new_height > max_height
          scale  = max_height.to_f / new_height.to_f
          new_height = max_height
          new_width  = (scale * new_width).to_i
        end
      end
      imlib_context_set_anti_alias(1)
      resized_ptr = imlib_create_cropped_scaled_image(0, 0, imlib_image_get_width, imlib_image_get_height, new_width, new_height)
      raise if resized_ptr.null?
      instantiate(resized_ptr)
    end
    
    def crop(x, y, width, height)
      context_set_image
      cropped_ptr = imlib_create_cropped_image(x, y, width, height)
      raise if cropped_ptr.null?
      instantiate(cropped_ptr)
    end
    
    def save(path, format = nil)
      context_set_image
      format ||= format_from_filename(path) || 'jpg'
      imlib_image_set_format(format)
      imlib_save_image(path)
      true
    end
    
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} width=#{width} height=#{height}>"
    end
    
    private
    
    def format_from_filename(path)
      File.extname(path)[1..-1]
    end
    
    def context_set_image
      imlib_context_set_image(ptr)
    end
    
    def instantiate(ptr)
      self.class.send(:new, ptr)
    end
    
  end
end
