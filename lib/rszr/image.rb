module Rszr
  class Image
    GRAVITIES = [true, :center, :n, :nw, :w, :sw, :s, :se, :e, :ne].freeze
    
    extend Identification
    include Buffered
    include Orientation
    
    class << self

      def load(path, autorotate: Rszr.autorotate, **opts)
        path = path.to_s
        raise FileNotFound unless File.exist?(path)
        image = _load(path)
        autorotate(image, path) if autorotate
        image
      end
      alias :open :load
      
      def load_data(data, autorotate: Rszr.autorotate, **opts)
        raise LoadError, 'Unknown format' unless format = identify(data)
        with_tempfile(format, data) do |file|
          load(file.path, autorotate: autorotate, **opts)
        end
      end

    end

    def dimensions
      [width, height]
    end
    
    def format
      fmt = _format
      fmt == 'jpg' ? 'jpeg' : fmt
    end
    
    def format=(fmt)
      fmt = fmt.to_s if fmt.is_a?(Symbol)
      self._format = fmt
    end
    
    def [](x, y)
      if x >= 0 && x <= width - 1 && y >= 0 && y <= height - 1
        Color::RGBA.new(*_pixel(x, y))
      end
    end

    def inspect
      fmt = format
      fmt = " #{fmt.upcase}" if fmt
      "#<#{self.class.name}:0x#{object_id.to_s(16)} #{width}x#{height}#{fmt}>"
    end

    module Transformations
      def resize(*args, **opts)
        _resize(false, *calculate_size(*args,  **opts))
      end

      def resize!(*args, **opts)
        _resize(true, *calculate_size(*args, **opts))
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
      
      # horizontal
      def flop
        dup.flop!
      end
      
      # vertical
      def flip
        dup.flip!
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
      
      def brighten(*args, **opts)
        dup.brighten!(*args, **opts)
      end
      
      def contrast!(value, r: nil, g: nil, b: nil, a: nil)
        raise ArgumentError, 'illegal contrast (must be > 0)' if value < 0
        filter!("colormod(contrast=#{value.to_f});")
      end
      
      def contrast(*args, **opts)
        dup.contrast!(*args, **opts)
      end
      
      def gamma!(value, r: nil, g: nil, b: nil, a: nil)
        #raise ArgumentError, 'illegal gamma (must be > 0)' if value < 0
        filter!("colormod(gamma=#{value.to_f});")
      end
      
      def gamma(*args, **opts)
        dup.gamma!(*args, **opts)
      end
    end
    
    include Transformations

    def save(path, format: nil, quality: nil, interlace: false)
      format ||= format_from_filename(path) || self.format || 'jpg'
      raise ArgumentError, "invalid quality #{quality.inspect}" if quality && !(0..100).cover?(quality)
      ensure_path_is_writable(path)
      _save(path.to_s, format.to_s, quality, interlace)
    end
    
    def save_data(format: nil, quality: nil)
      format ||= self.format || 'jpg'
      with_tempfile(format) do |file|
        save(file.path, format: format, quality: quality)
        file.rewind
        file.read
      end
    end

    private
    
    # 0.5               0 < scale < 1
    # 400, 300          fit box
    # 400, :auto        fit width, auto height
    # :auto, 300        auto width, fit height
    # 400, 300, crop: :center_middle
    # 400, 300, background: rgba
    # 400, 300, skew: true
    
    def calculate_size(*args, crop: nil, skew: nil, inflate: true)
      #options = args.last.is_a?(Hash) ? args.pop : {}
      #assert_valid_keys options, :crop, :background, :skew  #:extend, :width, :height, :max_width, :max_height, :box
      if args.size == 1
        calculate_size_for_scale(args.first)
      elsif args.size == 2
        box_width, box_height = args
        if args.include?(:auto)
          calculate_size_for_auto(box_width, box_height)
        elsif box_width.is_a?(Numeric) && box_height.is_a?(Numeric)
          if not inflate and width <= box_width and height <= box_height
            [0, 0, width, height, width, height]
          elsif skew
            calculate_size_for_skew(box_width, box_height)
          elsif crop
            calculate_size_for_crop(box_width, box_height, crop)
          else
            calculate_size_for_limit(box_width, box_height)
          end
        end
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 1..2)"
      end
    end
    
    def calculate_size_for_scale(factor)
      raise ArgumentError, "scale factor #{factor.inspect} out of range" unless factor > 0 && factor < 1
      [0, 0, width, height, (width.to_f * factor).round, (height.to_f * factor).round]
    end
    
    def calculate_size_for_skew(box_width, box_height)
      [0, 0, width, height, box_width, box_height]
    end

    def calculate_size_for_auto(box_width, box_height)
      if :auto == box_width && box_height.is_a?(Numeric)
        new_height = box_height
        new_width = (box_height.to_f / height.to_f * width.to_f).round
      elsif box_width.is_a?(Numeric) && :auto == box_height
        new_width = box_width
        new_height = (box_width.to_f / width.to_f * height.to_f).round
      else
        raise ArgumentError, "unconclusive arguments #{box_width.inspect}, #{box_height.inspect}"
      end
      [0, 0, width, height, new_width, new_height]
    end

    def calculate_size_for_crop(box_width, box_height, crop)
      raise ArgumentError, "invalid crop gravity" unless GRAVITIES.include?(crop)
      aspect = width.to_f / height.to_f
      box_aspect = box_width.to_f / box_height.to_f
      if aspect >= box_aspect # wider than box
        src_width = (box_width.to_f * height.to_f / box_height.to_f).round
        src_height = height
        x = crop_horizontally(src_width, crop)
        y = 0
      else # narrower than box
        src_width = width
        src_height = (box_height.to_f * width.to_f / box_width.to_f).round
        x = 0
        y = crop_vertically(src_height, crop)
      end
      [x, y, src_width, src_height, box_width, box_height]
    end
    
    def crop_horizontally(src_width, crop)
      case crop
      when :nw, :w, :sw then 0
      when :ne, :e, :se then width - src_width
      else
        ((width - src_width).to_f / 2.to_f).round
      end
    end
    
    def crop_vertically(src_height, crop)
      case crop
      when :nw, :n, :ne then 0
      when :sw, :s, :se then height - src_height
      else
        ((height - src_height).to_f / 2.to_f).round
      end
    end
    
    def calculate_size_for_limit(box_width, box_height)
      scale = width.to_f / height.to_f
      box_scale = box_width.to_f / box_height.to_f
      if scale >= box_scale # wider
        new_width = box_width
        new_height = (height.to_f * box_width.to_f / width.to_f).round
      else # narrower
        new_height = box_height
        new_width = (width.to_f * box_height.to_f / height.to_f).round
      end
      [0, 0, width, height, new_width, new_height]
    end

    def format_from_filename(path)
      if extension = File.extname(path)[1..-1]
        extension.downcase
      end
    end
    
    def ensure_path_is_writable(path)
      path = Pathname.new(path)
      path.dirname.realpath.writable?
    rescue Errno::ENOENT => e
      raise SaveError, 'Non-existant path component'
    rescue SystemCallError => e
      raise SaveError, e.message
    end

    def assert_valid_keys(hsh, *valid_keys)
      if unknown_key = (hsh.keys - valid_keys).first
        raise ArgumentError.new("Unknown key: #{unknown_key.inspect}. Valid keys are: #{valid_keys.map(&:inspect).join(', ')}")
      end
    end
    
  end
end
