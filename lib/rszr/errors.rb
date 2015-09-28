module Rszr
  class Error < StandardError; end
  
  class FileNotFound < Error; end
  class ImageLoadError < Error; end
  class TransformationError < Error; end
  
end