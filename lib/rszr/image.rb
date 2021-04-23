module Rszr
  class Image
    
    class << self
      
      def load(path, autorotate: Rszr.autorotate, **opts)
        path = path.to_s
        raise FileNotFound unless File.exist?(path)
        _load(path, autorotate)
      end
      alias :open :load
      
    end

    def dimensions
      [width, height]
    end
    
    def format=(fmt)
      fmt = fmt.to_s if fmt.is_a?(Symbol)
      self._format = fmt
    end

    def inspect
      fmt = format
      fmt = " #{fmt.upcase}" if fmt
      "#<#{self.class.name}:0x#{object_id.to_s(16)} #{width}x#{height}#{fmt}>"
    end

    module Transformations
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
      
      def turn(orientation)
        dup.turn!(orientation)
      end

      def turn!(orientation)
        orientation = orientation.abs + 2 if orientation.negative?
        _turn!(orientation % 4)
      end
    
      def rotate(deg)
        _rotate(false, deg.to_f * Math::PI / 180.0)
      end
    
      def rotate!(deg)
        _rotate(true, deg.to_f * Math::PI / 180.0)
      end
    
      def sharpen(radius)
        dup.sharpen!(radius)
      end
    
      def sharpen!(radius)
        raise ArgumentError, 'illegal radius' if radius < 0
        _sharpen!(radius)
      end
    
      def blur(radius)
        dup.blur!(radius)
      end
    
      def blur!(radius)
        raise ArgumentError, 'illegal radius' if radius < 0
        _sharpen!(-radius)
      end
      
      def filter(filter_expr)
        dup.filter!(filter_expr)
      end
      
      def brighten!(value, r: nil, g: nil, b: nil, a: nil)
        raise ArgumentError, 'illegal brightness' if value > 1 || value < -1
        filter!("colormod(brightness=#{value.to_f});")
      end
      
      def brighten(*args)
        dup.brighten!(*args)
      end
      
      def contrast!(value, r: nil, g: nil, b: nil, a: nil)
        raise ArgumentError, 'illegal contrast (must be > 0)' if value < 0
        filter!("colormod(contrast=#{value.to_f});")
      end
      
      def contrast(*args)
        dup.contrast!(*args)
      end
      
      def gamma!(value, r: nil, g: nil, b: nil, a: nil)
        #raise ArgumentError, 'illegal gamma (must be > 0)' if value < 0
        filter!("colormod(gamma=#{value.to_f});")
      end
      
      def gamma(*args)
        dup.gamma!(*args)
      end
    end
    
    include Transformations

    def save(path, format: nil, quality: nil)
      format ||= format_from_filename(path) || self.format || 'jpg'
      raise ArgumentError, "invalid quality #{quality.inspect}" if quality && !(0..100).cover?(quality)
      _save(path.to_s, format.to_s, quality)
    end

    private
    
    # 0.5               scale > 0
    # 400, 300          fit box
    # 400, :auto        fit width, auto height
    # :auto, 300        auto width, fit height
    # 400, 300, crop: :center_middle
    # 400, 300, background: rgba
    # 400, 300, skew: true
    
    def calculate_size(*args, upsize: false, crop: nil, background: nil, skew: false)
      case args.size
      when 1
        scale_size(args.first)
      when 2
        box_width, box_height = args
        if box_width.is_a?(Numeric) && box_height.is_a?(Numeric)
          bounding_box_size(box_width, box_height, upsize: upsize, crop: crop, skew: skew)
        else
          auto_box_size(box_width, box_height, upsize: upsize)
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1..2)"
      end
    end
    
    def scale_size(factor)
      raise ArgumentError, "scale factor #{factor.inspect} out of range" unless factor > 0
      [0, 0, width, height, (width.to_f * factor).round, (height.to_f * factor).round]
    end
    
    def bounding_box_size(box_width, box_height, upsize: false, crop: nil, skew: false)
      original_width, original_height = width, height
      x = y = 0
      if skew
        new_width, new_height = box_width, box_height
      else
        original_ratio = original_width.to_f / original_height.to_f
        box_ratio = box_width.to_f / box_height.to_f
        if original_ratio >= box_ratio # wider than box
          if original_width < box_width and not upsize
            new_width, new_height = original_width, original_height
          elsif crop
            new_width = box_width
            new_height = original_height.to_f * box_ratio
            # TODO x, y
          else
            new_width = box_width
            new_height = box_height
            x = (original_width - original_width * original_height / new_height) / 2.0
          end
        else # narrower than box
          if box_height > original_height and not upsize
            new_width, new_height = original_width, original_height
          elsif crop
            # TODO
          else
            new_height = box_height
            new_width = original_width.to_f * box_height.to_f / original_height.to_f
          end
        end
      end
      [0, 0, original_width, original_height, new_width.round, new_height.round]
    end
    
    def crop_box_size(box_width, box_height, upsize: false)
      original_width, original_height = width, height
      x = y = 0
      # TODO
    end
    
    def auto_box_size(box_width, box_height, upsize: false)
      original_width, original_height = width, height
      if :auto == box_width && box_height.is_a?(Numeric)
        if box_height > original_height and not upsize
          new_width, new_height = original_width, original_height
        else
          new_height = box_height
          new_width = box_height.to_f / original_height.to_f * original_width.to_f
        end
      elsif box_width.is_a?(Numeric) && :auto == box_height
        if box_width > original_width and not upsize
          new_width, new_height = original_width, original_height
        else
          new_width = box_width
          new_height = box_width.to_f / original_width.to_f * original_height.to_f
        end
      else
        raise ArgumentError, "unconclusive arguments #{box_width} x #{box_height}"
      end
      [0, 0, original_width, original_height, new_width.round, new_height.round]
    end

    def format_from_filename(path)
      File.extname(path)[1..-1].to_s.downcase
    end

    def assert_valid_keys(hsh, *valid_keys)
      if unknown_key = (hsh.keys - valid_keys).first
        raise ArgumentError.new("Unknown key: #{unknown_key.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
      end
    end
    
  end
end
