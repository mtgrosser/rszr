#ifndef RUBY_RSZR_IMAGE
#define RUBY_RSZR_IMAGE

#include "rszr.h"
#include "image.h"
#include "errors.h"

VALUE cImage = Qnil;


static void rszr_free_image(Imlib_Image image)
{
  imlib_context_set_image(image);
  imlib_free_image();
}


static void rszr_image_deallocate(rszr_image_handle * handle)
{
  // fprintf(stderr, "rszr_image_deallocate");
  if (handle->image) {
    // fprintf(stderr, ": freeing");
    rszr_free_image(handle->image);
    handle->image = NULL;
  }
  free(handle);
  // fprintf(stderr, "\n");
}


static void rszr_image_autorotate(Imlib_Image image, char * path)
{
  ExifData * exifData;
  ExifByteOrder byteOrder;
  ExifEntry * exifEntry;
  int orientation = 0;
  int turns = 0;
  
  exifData = exif_data_new_from_file(path);
  
  if (exifData) {
    byteOrder = exif_data_get_byte_order(exifData);
    exifEntry = exif_data_get_entry(exifData, EXIF_TAG_ORIENTATION);
    if (exifEntry) {
      orientation = exif_get_short(exifEntry->data, byteOrder);
    }
  }

  if (orientation < 2 || orientation > 8) return;
  
  imlib_context_set_image(image);
  
  if (orientation == 2 || orientation == 4 || orientation == 5 || orientation == 7) {
    imlib_image_flip_horizontal();
  }
  
  if (orientation == 5 || orientation == 6) {
    imlib_image_orientate(1);
  } else if (orientation == 3 || orientation == 4) {
    imlib_image_orientate(2);
  } else if (orientation == 7 || orientation == 8) {
    imlib_image_orientate(3);
  }
}


static VALUE rszr_image_s_allocate(VALUE klass)
{
  rszr_image_handle * handle = calloc(1, sizeof(rszr_image_handle));
  return Data_Wrap_Struct(klass, NULL, rszr_image_deallocate, handle);
}


static VALUE rszr_image_initialize(VALUE self, VALUE rb_width, VALUE rb_height)
{
  rszr_image_handle * handle;
  
  Check_Type(rb_width,  T_FIXNUM);
  Check_Type(rb_height, T_FIXNUM);

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  handle->image = imlib_create_image(FIX2INT(rb_width), FIX2INT(rb_height));

  return self;
}


static VALUE rszr_image_s__load(VALUE klass, VALUE rb_path, VALUE autorotate)
{
  rszr_image_handle * handle;
  Imlib_Image image;
  char * path;
  Imlib_Load_Error error;
  VALUE oImage;
  
  path = StringValueCStr(rb_path);

  imlib_set_cache_size(0);
  image = imlib_load_image_with_error_return(path, &error);
  
  if (!image) {
    rszr_raise_load_error(error);
    return Qnil;
  }
  
  if (RTEST(autorotate)) rszr_image_autorotate(image, path);
  
  oImage = rszr_image_s_allocate(cImage);
  Data_Get_Struct(oImage, rszr_image_handle, handle);
  handle->image = image;
  return oImage;
}


static VALUE rszr_image_format_get(VALUE self)
{
  rszr_image_handle * handle;
  char * format;
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  format = imlib_image_format();
  
  if (format) {
    return rb_str_new2(format);
  } else {
    return Qnil;
  }
}


static VALUE rszr_image__format_set(VALUE self, VALUE rb_format)
{
  rszr_image_handle * handle;
  char * format = StringValueCStr(rb_format);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_set_format(format);
  
  return self;
}


static VALUE rszr_image_width(VALUE self)
{
  rszr_image_handle * handle;
  int width;
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  width = imlib_image_get_width();
  
  return INT2NUM(width);
}


static VALUE rszr_image_height(VALUE self)
{
  rszr_image_handle * handle;
  int height;
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  height = imlib_image_get_height();
  
  return INT2NUM(height);
}

/*
static VALUE rszr_image_get_quality(VALUE self)
{
  rszr_image_handle * handle;
  int quality;
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  quality = imlib_image_get_attached_value("quality");
  
  if (quality) {
    return INT2NUM(quality);
  } else {
    return Qnil;
  }
}

static VALUE rszr_image_set_quality(VALUE self, VALUE rb_quality)
{
  rszr_image_handle * handle;
  int quality;
  
  Check_Type(rb_quality, T_FIXNUM);
  quality = FIX2INT(rb_quality);
  if (quality <= 0) {
    rb_raise(rb_eArgError, "quality must be >= 0");
    return Qnil;
  }
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_attach_data_value("quality", NULL, quality, NULL);
  
  return INT2NUM(quality);
}
*/

static VALUE rszr_image_dup(VALUE self)
{
  rszr_image_handle * handle;
  rszr_image_handle * cloned_handle;
  Imlib_Image cloned_image;
  VALUE oClonedImage;
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  cloned_image = imlib_clone_image();
  
  if (!cloned_image) {
    rb_raise(eRszrTransformationError, "error cloning image");
    return Qnil;
  }
  
  oClonedImage = rszr_image_s_allocate(cImage);
  Data_Get_Struct(oClonedImage, rszr_image_handle, cloned_handle);
  cloned_handle->image = cloned_image;

  return oClonedImage;
}


static VALUE rszr_image__turn_bang(VALUE self, VALUE orientation)
{
  rszr_image_handle * handle;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_orientate(NUM2INT(orientation));
  
  return self;
}


static VALUE rszr_image__rotate(VALUE self, VALUE bang, VALUE rb_angle)
{
  rszr_image_handle * handle;
  rszr_image_handle * rotated_handle;
  Imlib_Image rotated_image;
  VALUE oRotatedImage;
  double angle;
  
  angle = NUM2DBL(rb_angle);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  rotated_image = imlib_create_rotated_image(angle);
  
  if (!rotated_image) {
    rb_raise(eRszrTransformationError, "error rotating image");
    return Qnil;
  }
  
  if (RTEST(bang)) {
    rszr_free_image(handle->image);
    handle->image = rotated_image;
    
    return self;
  }
  else {
    oRotatedImage = rszr_image_s_allocate(cImage);
    Data_Get_Struct(oRotatedImage, rszr_image_handle, rotated_handle);
    rotated_handle->image = rotated_image;
  
    return oRotatedImage;
  }
}


static VALUE rszr_image_filter_bang(VALUE self, VALUE rb_filter_expr)
{
  rszr_image_handle * handle;
  Imlib_Image image;
  char * filter_expr;
  
  filter_expr = StringValueCStr(rb_filter_expr);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_apply_filter(filter_expr);
  
  return self;
}


static VALUE rszr_image__brighten_bang(VALUE self, VALUE rb_brightness)
{
  rszr_image_handle * handle;
  double brightness;
  
  brightness = NUM2DBL(rb_brightness);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_apply_filter("brightness(10);");
  
  return self;
}


static VALUE rszr_image__sharpen_bang(VALUE self, VALUE rb_radius)
{
  rszr_image_handle * handle;
  int radius;
  
  radius = NUM2INT(rb_radius);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  
  if (radius >= 0) {
    imlib_image_sharpen(radius);
  } else {
    imlib_image_blur(radius);
  }
  
  return self;
}


static Imlib_Image rszr_create_cropped_scaled_image(const Imlib_Image image, VALUE rb_src_x, VALUE rb_src_y, VALUE rb_src_w, VALUE rb_src_h, VALUE rb_dst_w, VALUE rb_dst_h)
{
  Imlib_Image resized_image;
  
  int src_x = NUM2INT(rb_src_x);
  int src_y = NUM2INT(rb_src_y);
  int src_w = NUM2INT(rb_src_w);
  int src_h = NUM2INT(rb_src_h);
  int dst_w = NUM2INT(rb_dst_w);
  int dst_h = NUM2INT(rb_dst_h);

  // TODO: raise if <= 0

  imlib_context_set_image(image);
  imlib_context_set_anti_alias(1);
  resized_image = imlib_create_cropped_scaled_image(src_x, src_y, src_w, src_h, dst_w, dst_h);
  
  if (!resized_image) {
    rb_raise(eRszrTransformationError, "error resizing image");
    return NULL;
  }
  
  return resized_image;
}


static VALUE rszr_image__resize(VALUE self, VALUE bang, VALUE rb_src_x, VALUE rb_src_y, VALUE rb_src_w, VALUE rb_src_h, VALUE rb_dst_w, VALUE rb_dst_h)
{
  rszr_image_handle * handle;
  Imlib_Image resized_image;
  rszr_image_handle * resized_handle;
  VALUE oResizedImage;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  resized_image = rszr_create_cropped_scaled_image(handle->image, rb_src_x, rb_src_y, rb_src_w, rb_src_h, rb_dst_w, rb_dst_h);
  if (!resized_image) return Qfalse;
  
  if (RTEST(bang)) {
    rszr_free_image(handle->image);
    handle->image = resized_image;
    
    return self;
  }
  else {
    oResizedImage = rszr_image_s_allocate(cImage);
    Data_Get_Struct(oResizedImage, rszr_image_handle, resized_handle);
    resized_handle->image = resized_image;
  
    return oResizedImage;
  }
}


static Imlib_Image rszr_create_cropped_image(const Imlib_Image image, VALUE rb_x, VALUE rb_y, VALUE rb_w, VALUE rb_h)
{
  Imlib_Image cropped_image;
  
  int x = NUM2INT(rb_x);
  int y = NUM2INT(rb_y);
  int w = NUM2INT(rb_w);
  int h = NUM2INT(rb_h);
  
  imlib_context_set_image(image);
  cropped_image = imlib_create_cropped_image(x, y, w, h);
  
  if (!cropped_image) {
    rb_raise(eRszrTransformationError, "error cropping image");
    return NULL;
  }
  
  return cropped_image;
}


static VALUE rszr_image__crop(VALUE self, VALUE bang, VALUE rb_x, VALUE rb_y, VALUE rb_w, VALUE rb_h)
{
  rszr_image_handle * handle;
  Imlib_Image cropped_image;
  rszr_image_handle * cropped_handle;
  VALUE oCroppedImage;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  cropped_image = rszr_create_cropped_image(handle->image, rb_x, rb_y, rb_w, rb_h);
  if (!cropped_image) return Qfalse;
  
  if (RTEST(bang)) {
    rszr_free_image(handle->image);
    handle->image = cropped_image;
    
    return self;
  }
  else {
    oCroppedImage = rszr_image_s_allocate(cImage);
    Data_Get_Struct(oCroppedImage, rszr_image_handle, cropped_handle);
    cropped_handle->image = cropped_image;
  
    return oCroppedImage;
  }
}


static VALUE rszr_image__save(VALUE self, VALUE rb_path, VALUE rb_format, VALUE rb_quality)
{
  rszr_image_handle * handle;
  char * path;
  char * format;
  int quality;
  Imlib_Load_Error save_error;
  
  path = StringValueCStr(rb_path);
  format = StringValueCStr(rb_format);
  quality = (NIL_P(rb_quality)) ? 0 : FIX2INT(rb_quality);

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_set_format(format);
  if (quality)
    imlib_image_attach_data_value("quality", NULL, quality, NULL);
  imlib_save_image_with_error_return(path, &save_error);
  
  if (save_error) {
    rszr_raise_save_error(save_error);
    return Qfalse;
  }
  
  return Qtrue;
}

void Init_rszr_image()
{
  cImage = rb_define_class_under(mRszr, "Image", rb_cObject);
  rb_define_alloc_func(cImage, rszr_image_s_allocate);

  // Class methods
  rb_define_private_method(rb_singleton_class(cImage), "_load", rszr_image_s__load, 2);

  // Instance methods
  rb_define_method(cImage, "initialize",  rszr_image_initialize, 2);
  rb_define_method(cImage, "width",       rszr_image_width, 0);
  rb_define_method(cImage, "height",      rszr_image_height, 0);
  rb_define_method(cImage, "format",      rszr_image_format_get, 0);
  rb_define_method(cImage, "dup",         rszr_image_dup, 0);
  rb_define_method(cImage, "filter!",     rszr_image_filter_bang, 1);
  
  // rb_define_method(cImage, "quality",     rszr_image_get_quality, 0);
  // rb_define_method(cImage, "quality=",    rszr_image_set_quality, 1);
  
  rb_define_protected_method(cImage, "_format=", rszr_image__format_set, 1);
  
  rb_define_private_method(cImage, "_resize",  rszr_image__resize, 7);
  rb_define_private_method(cImage, "_crop",    rszr_image__crop, 5);
  rb_define_private_method(cImage, "_turn!",   rszr_image__turn_bang, 1);
  rb_define_private_method(cImage, "_rotate",  rszr_image__rotate, 2);
  rb_define_private_method(cImage, "_sharpen!",   rszr_image__sharpen_bang, 1);
  rb_define_private_method(cImage, "_brighten!",  rszr_image__brighten_bang, 1);
  
  rb_define_private_method(cImage, "_save",       rszr_image__save, 3);
}

#endif
