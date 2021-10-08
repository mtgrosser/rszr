module Rszr
  module Orientation
    ROTATIONS = { 5 => 1, 6 => 1, 3 => 2, 4 => 2, 7 => 3, 8 => 3 }
    
    def self.included(base)
      base.extend(ClassMethods)
      base.attr_reader :original_orientation
    end
    
    module ClassMethods
    
      private
    
      def autorotate(image, path)
        return unless %w[jpeg tiff].include?(image.format)
        File.open(path) do |file|
          if orientation = send("parse_#{image.format}_orientation", file) and (1..8).member?(orientation)
            image.instance_variable_set :@original_orientation, orientation
            image.flop! if [2, 4, 5, 7].include?(orientation)
            image.turn!(ROTATIONS[orientation]) if ROTATIONS.key?(orientation)
          end
        end
      end
    
      def parse_tiff_orientation(data)
        exif_parse_orientation(Stream.new(data))
      end
    
      def parse_jpeg_orientation(data)
        stream = Stream.new(data)
        exif = nil
        state = nil
        loop do
          state = case state
          when nil
            stream.skip(2)
            :started
          when :started
            stream.read_byte == 0xFF ? :sof : :started
          when :sof
            case stream.read_byte
            when 0xe1 # APP1
              skip_chars = stream.read_int - 2
              app1 = Stream.new(stream.read(skip_chars))
              if app1.read(4) == 'Exif'
                app1.skip(2)
                orientation = exif_parse_orientation(app1.fast_forward)# rescue nil
                return orientation
              end
              :started
            when 0xe0..0xef
              :skipframe
            when 0xC0..0xC3, 0xC5..0xC7, 0xC9..0xCB, 0xCD..0xCF
              :readsize
            when 0xFF
              :sof
            else
              :skipframe
            end
          when :skipframe
            skip_chars = stream.read_int - 2
            stream.skip(skip_chars)
            :started
          when :readsize
            # stream.skip(3)
            # height = stream.read_int
            # width = stream.read_int
            return exif&.orientation
          end
        end
      end
    
      def exif_byte_order(stream)
        byte_order = stream.read(2)
        case byte_order
        when 'II'
          %w[v V]
        when 'MM'
          %w[n N]
        else
          raise LoadError
        end
      end

      def exif_parse_ifd(stream, short)
        tag_count = stream.read(2).unpack(short)[0]
        tag_count.downto(1) do
          type = stream.read(2).unpack(short)[0]
          stream.read(6)
          data = stream.read(2).unpack(short)[0]
          return data if 0x0112 == type
          stream.read(2)
        end
        nil
      end

      def exif_parse_orientation(stream)
        short, long = exif_byte_order(stream)
        stream.read(2) # 42
        offset = stream.read(4).unpack(long)[0]
        stream.skip(offset - 8)
        exif_parse_ifd(stream, short)
      end
    end
    
  end
end
