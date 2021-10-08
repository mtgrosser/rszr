# Type reader adapted from fastimage
# https://github.com/sdsykes/fastimage/

module Rszr
  module Identification
    
    private
    
    def identify(data)
      case data[0, 2]
      when 'BM'
        :bmp
      when 'GI'
        :gif
      when 0xff.chr + 0xd8.chr
        :jpeg
      when 0x89.chr + 'P'
        :png
      when 'II', 'MM'
        case data[0, 11][8..10] # @stream.peek(11)[8..10]
        when 'APC', "CR\002"
          nil  # do not recognise CRW or CR2 as tiff
        else
          :tiff
        end
      when '8B'
        :psd
      when "\0\0"
        case data[0, 3].bytes.last #@stream.peek(3).bytes.to_a.last
        when 0
          # http://www.ftyps.com/what.html
          # HEIC is composed of nested "boxes". Each box has a header composed of
          # - Size (32 bit integer)
          # - Box type (4 chars)
          # - Extended size: only if size === 1, the type field is followed by 64 bit integer of extended size
          # - Payload: Type-dependent
          case data[0, 12][4..-1] #@stream.peek(12)[4..-1]
          when 'ftypheic'
            :heic
          when 'ftypmif1'
            :heif
          end
        # ico has either a 1 (for ico format) or 2 (for cursor) at offset 3
        when 1 then :ico
        when 2 then :cur
        end
      when 'RI'
        :webp if data[0, 12][8..11] == 'WEBP' #@stream.peek(12)[8..11] == "WEBP"
      when "<s"
        :svg if data[0, 4] == '<svg' #@stream.peek(4) == "<svg"
      when /\s\s|\s<|<[?!]/, 0xef.chr + 0xbb.chr
        # Peek 10 more chars each time, and if end of file is reached just raise
        # unknown. We assume the <svg tag cannot be within 10 chars of the end of
        # the file, and is within the first 250 chars.
        :svg if (1..25).detect { |n| data[0, 10 * n]&.include?('<svg') }
      end
    end

  end
end
