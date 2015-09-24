module Rszr
  module LIB
    extend Fiddle::Importer
    
    dlload case RbConfig::CONFIG['arch']
    when /darwin/ then 'libImlib2.dylib'
    when /mswin32/, /cygwin/ then 'imlib2.dll'
    else
      'libImlib2.so'
    end
    
    typealias 'Imlib_Image', 'void *'
    typealias 'Imlib_Context', 'void *'

    #typedef void       *Imlib_Color_Modifier;
    #typedef void       *Imlib_Updates;
    #typedef void       *Imlib_Font;
    #typedef void       *Imlib_Color_Range;
    #typedef void       *Imlib_Filter;
    #typedef struct _imlib_border Imlib_Border;
    #typedef struct _imlib_color Imlib_Color;
    #typedef void       *ImlibPolygon;
    
    extern 'Imlib_Image imlib_load_image(const char *)'
    extern 'Imlib_Image imlib_load_image_without_cache(const char *)'
    extern 'void        imlib_context_set_image(Imlib_Image)'
    extern 'int         imlib_image_get_width()'
    extern 'int         imlib_image_get_height()'
    extern 'void        imlib_context_set_anti_alias(char)'

    # source_x, source_y, source_width, source_height, destination_width, destination_height
    extern 'Imlib_Image imlib_create_cropped_scaled_image(int, int, int, int, int, int)'
    # x, y, width, height
    extern 'Imlib_Image imlib_create_cropped_image(int, int, int, int)'
    
    extern 'void        imlib_image_set_format(const char *)'
    extern 'void        imlib_save_image(const char *)'
    #extern 'void        imlib_save_image_with_error_return(const char *, Imlib_Load_Error *)'
    
    extern 'void        imlib_free_image()'
    extern 'void        imlib_free_image_and_decache()'
    
  end
end
