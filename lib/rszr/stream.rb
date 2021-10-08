module Rszr
  class Stream
    attr_reader :pos

    def initialize(data)
      @data = data.force_encoding('BINARY')
      @pos = 0
    end
    
    def read(n)
      @data[@pos, n].tap { @pos += n }
    end
    
    def peek(n)
      @data[@pos, n]
    end
    
    def skip(n)
      @pos += n
    end

    def substream
      self.class.new(@data[@pos..-1])
    end

    def fast_forward
      @data = @data[@pos..-1]
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
