module Rszr
  class BatchTransformation
    attr_reader :transformations, :image
    
    def initialize(path, **opts)
      puts "INITIALIZED BATCH for #{path}"
      @image = path.is_a?(Image) ? path : Image.load(path, **opts)
      @transformations = []
    end
    
    Image::Transformations.instance_methods.grep(/\w\z/) do |method|
      define_method method do |*args|
        transformations << [method, args]
        self
      end
    end
    
    def call
      transformations.each { |method, args| image.public_send("#{method}!", *args) }
      image
    end
  
  end
end
