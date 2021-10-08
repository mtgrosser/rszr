module Rszr
  class Stream
    attr_reader :pos, :data
    protected :data

    def initialize(data, start: 0)
      raise ArgumentError, 'start must be > 0' if start < 0
      @data = case data
        when IO then data
        when String then StringIO.new(data)
        when Stream then data.data
      else
        raise ArgumentError, "data must be File or String, got #{data.class}"
      end
      @data.binmode
      @data.seek(start, IO::SEEK_CUR)
      @pos = 0
    end
    
    def read(n)
      @data.read(n).tap { @pos += n }
    end
    
    def peek(n)
      old_pos = @data.pos
      @data.read(n)
    ensure
      @data.pos = old_pos
    end
    
    def skip(n)
      @data.seek(n, IO::SEEK_CUR).tap { @pos += n }
    end

    def substream
      self.class.new(self, pos)
    end

    def fast_forward
      @pos = 0
      self
    end

    def read_byte
      read(1)[0].ord
    end

    def read_int
      read(2).unpack('n')[0]
    end

    def read_string_int
      value = []
      while read(1) =~ /(\d)/
        value << $1
      end
      value.join.to_i
    end

  end
end
