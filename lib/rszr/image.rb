module Rszr
  class Image

    class << self
      
      def load(path, options = {})
        path = path.to_s
        raise FileNotFound unless File.exist?(path)
        _load(path)
      end
      alias :open :load
      
    end

    def dimensions
      [width, height]
    end

    def inspect
      fmt = format
      fmt = " #{fmt.upcase}" if fmt
      "#<#{self.class.name}:0x#{object_id.to_s(16)} #{width}x#{height}#{fmt}>"
    end

    def resize(*args)
      _resize(false, *calculate_size(*args))
    end

    def resize!(*args)
      _resize(true, *calculate_size(*args))
    end

    def crop(x, y, width, height)
      _crop(false, x, y, width, height)
    end

    def crop!(x, y, width, height)
      _crop(true, x, y, width, height)
    end

    def turn!(orientation)
      orientation = orientation.abs + 2 if orientation.negative?
      _turn!(orientation % 4)
    end

    def save(path, format = nil)
      format ||= format_from_filename(path) || 'jpg'
      _save(path.to_s, format.to_s)
    end

    private
    
    # 0.5               0 < scale < 1
    # 400, 300          fit box
    # 400, :auto        fit width, auto height
    # :auto, 300        auto width, fit height
    # 400, 300, crop: :center_middle
    # 400, 300, background: rgba
    # 400, 300, aspect: false
    
    def calculate_size(*args)
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
      [x, y, original_width, original_height, new_width.round, new_height.round]
    end
    
    def format_from_filename(path)
      File.extname(path)[1..-1]
    end

    def assert_valid_keys(hsh, *valid_keys)
      if unknown_key = (hsh.keys - valid_keys).first
        raise ArgumentError.new("Unknown key: #{unknown_key.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
      end
    end
    
  end
end
