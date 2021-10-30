require 'rszr'
require 'image_processing'

module ImageProcessing
  module Rszr
    extend Chainable

    class << self
      
      # Returns whether the given image file is processable.
      def valid_image?(file)
        ::Rszr::Image.load(file).width
        true
      rescue ::Rszr::Error
        false
      end
      
    end

    class Processor < ImageProcessing::Processor
      accumulator :image, ::Rszr::Image

      class << self

        # Loads the image on disk into a Rszr::Image object
        def load_image(path_or_image, **options)
          if path_or_image.is_a?(::Rszr::Image)
            path_or_image
          else
            ::Rszr::Image.load(path_or_image)
          end
          # TODO: image = image.autorot if autorot && !options.key?(:autorotate)
        end

        # Writes the image object to disk. 
        # Accepts additional options (quality, format).
        def save_image(image, destination_path, **options)
          image.save(destination_path, **options)
        end

        # Calls the operation to perform the processing. If the operation is
        # defined on the processor (macro), calls it. Otherwise calls the
        # bang variant of the method directly on the Rszr image object.
        def apply_operation(accumulator, (name, args, block))
          return super if method_defined?(name)
          accumulator.send("#{name}!", *args, &block)
        end

      end
      
      # Resizes the image to not be larger than the specified dimensions.
      def resize_to_limit(width, height, **options)
        width, height = default_dimensions(width, height)
        thumbnail(width, height, inflate: false, **options)
      end

      # Resizes the image to fit within the specified dimensions.
      def resize_to_fit(width, height, **options)
        width, height = default_dimensions(width, height)
        thumbnail(width, height, **options)
      end

      # Resizes the image to fill the specified dimensions, applying any
      # necessary cropping.
      def resize_to_fill(width, height, gravity: :center, **options)
        thumbnail(width, height, crop: gravity, **options)
      end

      private

      def thumbnail(width, height, **options)
        image.resize!(width, height, **options)
      end

      def default_dimensions(width, height)
        raise Error, 'either width or height must be specified' unless width || height
        [width || :auto, height || :auto]
      end

    end
  end
end
