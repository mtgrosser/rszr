module Rszr
  class Error < StandardError; end

  class ErrorWithMessage < Error
    MESSAGES = [nil,
                'File does not exist',
                'File is a directory',
                'Read permission denied',
                'Unsupported format',
                'Path too long',
                'Non-existant path component',
                'Path component is not a directory',
                'Path outside address space',
                'Too many symbolic links',
                'Out of memory',
                'Out of file descriptors',
                'Write permission denied',
                'Out of disk space',
                'Unknown error']
    
    attr_reader :ptr
    
    def initialize
      @ptr = Fiddle::Pointer.malloc(Rszr::Lib.sizeof('Imlib_Load_Error'))
    end
    
    def error?
      return if ptr.null?
      0 != ptr[0]
    end
    
    def message
      MESSAGES[ptr[0]] unless ptr.null?
    end
  end

  
  class FileNotFound < Error; end
  class LoadError < ErrorWithMessage; end
  class TransformationError < Error; end
  class SaveError < ErrorWithMessage; end
end