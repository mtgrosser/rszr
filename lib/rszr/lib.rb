module Rszr
  
  module Lib
    extend Fiddle::Importer
    
    dlload case RbConfig::CONFIG['arch']
    when /darwin/ then 'libImlib2.dylib'
    when /mswin/, /cygwin/ then 'imlib2.dll'
    else
      'libImlib2.so'
    end
    
    typealias 'Imlib_Image',      'void *'
    typealias 'Imlib_Context',    'void *'
    typealias 'enum',             'int'
    typealias 'Imlib_Load_Error', 'enum'

    #typedef void       *Imlib_Color_Modifier;
    #typedef void       *Imlib_Updates;
    #typedef void       *Imlib_Font;
    #typedef void       *Imlib_Color_Range;
    #typedef void       *Imlib_Filter;
    #typedef struct _imlib_border Imlib_Border;
    #typedef struct _imlib_color Imlib_Color;
    #typedef void       *ImlibPolygon;
    
    extern 'int         imlib_get_cache_size()'
    extern 'void        imlib_set_cache_size(int)'
    
    extern 'Imlib_Image imlib_load_image(const char *)'
    extern 'Imlib_Image imlib_load_image_without_cache(const char *)'
    extern 'Imlib_Image imlib_load_image_with_error_return(const char *, Imlib_Load_Error *)'
    extern 'Imlib_Image imlib_create_image(int, int)'
    extern 'void        imlib_context_set_image(Imlib_Image)'
    extern 'int         imlib_image_get_width()'
    extern 'int         imlib_image_get_height()'
    extern 'void        imlib_context_set_anti_alias(char)'

    # source_x, source_y, source_width, source_height, destination_width, destination_height
    extern 'Imlib_Image imlib_create_cropped_scaled_image(int, int, int, int, int, int)'
    # x, y, width, height
    extern 'Imlib_Image imlib_create_cropped_image(int, int, int, int)'
    
    extern 'char *      imlib_image_format()'
    extern 'void        imlib_image_set_format(const char *)'
    extern 'void        imlib_save_image(const char *)'
    extern 'void        imlib_save_image_with_error_return(const char *, Imlib_Load_Error *)'
    
    extern 'void        imlib_free_image()'
    extern 'void        imlib_free_image_and_decache()'
    
    def self.delegate(base)
      Lib.methods.grep(/\Aimlib_/).each do |method|
        line_no = __LINE__; str = %Q{
          def #{method}(*args, &block)
            Lib.#{method}(*args, &block)
          end
        }
        base.class_eval(str, __FILE__, line_no)
      end
    end
    
  end
end
