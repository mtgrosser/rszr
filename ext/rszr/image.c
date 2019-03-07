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

static VALUE rszr_image_s__load(VALUE klass, VALUE rb_path)
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
  
  oImage = rszr_image_s_allocate(cImage);
  Data_Get_Struct(oImage, rszr_image_handle, handle);
  handle->image = image;
  return oImage;
}

static VALUE rszr_image_format(VALUE self)
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
static VALUE rszr_image_replace(VALUE self, VALUE rb_other)
{
  rszr_image_handle * handle;
  rszr_image_handle * other_handle;
  
  if (CLASS_OF(rb_other) != cImage) {
    rb_raise(rb_eArgError, "Rszr::Image required, got %s", rb_obj_classname(rb_other));
  }
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  Data_Get_Struct(rb_other, rszr_image_handle, other_handle);
  
  return self;
}
*/

/*
static VALUE rszr_image_turn(VALUE self, VALUE orientation)
{
  // void imlib_image_orientate(int orientation)
  return self;
}
*/

static Imlib_Image rszr_create_cropped_scaled_image(VALUE self, VALUE rb_src_x, VALUE rb_src_y, VALUE rb_src_w, VALUE rb_src_h, VALUE rb_dst_w, VALUE rb_dst_h)
{
  rszr_image_handle * handle;
  Imlib_Image resized_image;
  
  int src_x = NUM2INT(rb_src_x);
  int src_y = NUM2INT(rb_src_y);
  int src_w = NUM2INT(rb_src_w);
  int src_h = NUM2INT(rb_src_h);
  int dst_w = NUM2INT(rb_dst_w);
  int dst_h = NUM2INT(rb_dst_h);

  // TODO: raise if <= 0

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_context_set_anti_alias(1);
  resized_image = imlib_create_cropped_scaled_image(src_x, src_y, src_w, src_h, dst_w, dst_h);
  
  if (!resized_image) {
    rb_raise(eRszrTransformationError, "error resizing image");
    return NULL;
  }
  
  return resized_image;
}

static VALUE rszr_image__resize_bang(VALUE self, VALUE rb_src_x, VALUE rb_src_y, VALUE rb_src_w, VALUE rb_src_h, VALUE rb_dst_w, VALUE rb_dst_h)
{
  rszr_image_handle * handle;
  Imlib_Image resized_image;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  resized_image = rszr_create_cropped_scaled_image(self, rb_src_x, rb_src_y, rb_src_w, rb_src_h, rb_dst_w, rb_dst_h);
  if (!resized_image) return Qfalse;
  
  rszr_free_image(handle->image);
  handle->image = resized_image;
  
  return self;
}

static VALUE rszr_image__resize(VALUE self, VALUE rb_src_x, VALUE rb_src_y, VALUE rb_src_w, VALUE rb_src_h, VALUE rb_dst_w, VALUE rb_dst_h)
{
  rszr_image_handle * handle;
  Imlib_Image resized_image;
  rszr_image_handle * resized_handle;
  VALUE oResizedImage;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  resized_image = rszr_create_cropped_scaled_image(self, rb_src_x, rb_src_y, rb_src_w, rb_src_h, rb_dst_w, rb_dst_h);
  if (!resized_image) return Qfalse;
  
  oResizedImage = rszr_image_s_allocate(cImage);
  Data_Get_Struct(oResizedImage, rszr_image_handle, resized_handle);
  resized_handle->image = resized_image;
  
  return oResizedImage;
}

static VALUE rszr_image__save(VALUE self, VALUE rb_path, VALUE rb_format)
{
  rszr_image_handle * handle;
  char * path;
  char * format;
  Imlib_Load_Error save_error;
  
  path = StringValueCStr(rb_path);
  format = StringValueCStr(rb_format);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_set_format(format);
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
  rb_define_private_method(rb_singleton_class(cImage), "_load", rszr_image_s__load, 1);

  // Instance methods
  rb_define_method(cImage, "initialize",  rszr_image_initialize, 2);
  rb_define_method(cImage, "width",       rszr_image_width, 0);
  rb_define_method(cImage, "height",      rszr_image_height, 0);
  rb_define_method(cImage, "format",      rszr_image_format, 0);
  rb_define_private_method(cImage, "_resize!", rszr_image__resize, 6);
  rb_define_private_method(cImage, "_resize",  rszr_image__resize, 6);
  rb_define_private_method(cImage, "_save",     rszr_image__save, 2);
}

#endif
