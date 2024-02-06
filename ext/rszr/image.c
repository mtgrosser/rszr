#ifndef RUBY_RSZR_IMAGE
#define RUBY_RSZR_IMAGE

#include "rszr.h"
#include "image.h"
#include "errors.h"

VALUE cImage = Qnil;
VALUE cColorBase = Qnil;
VALUE cColorGradient = Qnil;
VALUE cColorPoint = Qnil;
VALUE cFill = Qnil;


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


static VALUE rszr_image__initialize(VALUE self, VALUE rb_width, VALUE rb_height)
{
  rszr_image_handle * handle;
  
  Check_Type(rb_width,  T_FIXNUM);
  Check_Type(rb_height, T_FIXNUM);

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  handle->image = imlib_create_image(FIX2INT(rb_width), FIX2INT(rb_height));

  return self;
}


static VALUE rszr_image_s__load(VALUE klass, VALUE rb_path, VALUE rb_immediately)
{
  rszr_image_handle * handle;
  Imlib_Image image;
  char * path;
  Imlib_Load_Error error;
  VALUE oImage;
  
  path = StringValueCStr(rb_path);

  imlib_set_cache_size(0);
  if (RTEST(rb_immediately)) {
    image = imlib_load_image_immediately_without_cache(path);
  } else {
    image = imlib_load_image_without_cache(path);
  }
  
  if (!image) {
    image = imlib_load_image_with_error_return(path, &error);
    
    if (!image) {
      rszr_raise_load_error(error);
      return Qnil;
    }
  }
  
  imlib_context_set_image(image);
  imlib_image_set_irrelevant_format(0);
  
  oImage = rszr_image_s_allocate(cImage);
  Data_Get_Struct(oImage, rszr_image_handle, handle);
  handle->image = image;
  return oImage;
}


static VALUE rszr_image__format_get(VALUE self)
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


static void rszr_image_color_set(VALUE rb_color)
{
  int r, g, b, a;

  if(!rb_obj_is_kind_of(rb_color, cColorBase) || RBASIC_CLASS(rb_color) == cColorBase) {
    rb_raise(rb_eArgError, "color must descend from Rszr::Color::Base");
  }

  r = FIX2INT(rb_funcall(rb_color, rb_intern("red"), 0));
  g = FIX2INT(rb_funcall(rb_color, rb_intern("green"), 0));
  b = FIX2INT(rb_funcall(rb_color, rb_intern("blue"), 0));
  a = FIX2INT(rb_funcall(rb_color, rb_intern("alpha"), 0));

  // TODO: use color model specific setter function
  imlib_context_set_color(r, g, b, a);
}


static VALUE rszr_image_alpha_get(VALUE self)
{
  rszr_image_handle * handle;

  Data_Get_Struct(self, rszr_image_handle, handle);

  imlib_context_set_image(handle->image);
  if (imlib_image_has_alpha()) {
    return Qtrue;
  }

  return Qfalse;
}

static VALUE rszr_image_alpha_set(VALUE self, VALUE rb_alpha)
{
  rszr_image_handle * handle;

  Data_Get_Struct(self, rszr_image_handle, handle);

  imlib_context_set_image(handle->image);
  imlib_image_set_has_alpha(RTEST(rb_alpha) ? 1 : 0);

  return Qnil;
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


static VALUE rszr_image__pixel_get(VALUE self, VALUE rb_x, VALUE rb_y)
{
  rszr_image_handle * handle;
  Imlib_Color color_return;
  VALUE rb_rgba;
  int x, y;
  
  Check_Type(rb_x, T_FIXNUM);
  x = FIX2INT(rb_x);
  Check_Type(rb_y, T_FIXNUM);
  y = FIX2INT(rb_y);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_query_pixel(x, y, &color_return);
  
  rb_rgba = rb_ary_new3(4, INT2NUM(color_return.red),
                           INT2NUM(color_return.green),
                           INT2NUM(color_return.blue),
                           INT2NUM(color_return.alpha));
  return rb_rgba;
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


static VALUE rszr_image_flop_bang(VALUE self)
{
  rszr_image_handle * handle;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_flip_horizontal();

  return self;
}


static VALUE rszr_image_flip_bang(VALUE self)
{
  rszr_image_handle * handle;

  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_image_flip_vertical();

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
  char * filter_expr;
  
  filter_expr = StringValueCStr(rb_filter_expr);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  imlib_apply_filter(filter_expr);
  
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
    imlib_image_blur(-radius);
  }
  
  return self;
}


static void rszr_desaturate_pixel(rszr_raw_pixel * pixel, int mode)
{
  uint8_t grey;
  if (mode == 2 || (mode == 0 && (pixel->blue > pixel->red && pixel->blue > pixel->green))) {
    // lightness
    grey = (pixel->blue + (pixel->red > pixel->green ? pixel->green : pixel->red)) / 2;
  } else if (mode == 1 || mode == 0) {
    // luminosity
    grey = 0.21 * pixel->red + 0.72 * pixel->green + 0.07 * pixel->blue;
  } else {
    // average
    grey = (pixel->red + pixel->green + pixel->blue) / 3;
  }
  pixel->red = grey;
  pixel->green = grey;
  pixel->blue = grey;
}

static VALUE rszr_image__desaturate_bang(VALUE self, VALUE rb_mode)
{
  rszr_image_handle * handle;
  rszr_raw_pixel * pixels;
  uint64_t size;
  int mode;
  
  mode = NUM2INT(rb_mode);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  
  imlib_context_set_image(handle->image);
  
  pixels = (rszr_raw_pixel *) imlib_image_get_data();
  if (pixels == NULL) {
    rb_raise(eRszrTransformationError, "error desaturating image");
    return Qnil;
  }
  
  size = imlib_image_get_width() * imlib_image_get_height();
  for (uint64_t i = 0; i < size; i++) {
    rszr_desaturate_pixel(&pixels[i], mode);
  }
  
  imlib_image_put_back_data((uint32_t *) pixels);
  
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
  imlib_context_set_dither(1);
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
  
  Check_Type(rb_x, T_FIXNUM);
  Check_Type(rb_y, T_FIXNUM);
  Check_Type(rb_w, T_FIXNUM);
  Check_Type(rb_h, T_FIXNUM);

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


static VALUE rszr_image__blend(VALUE self, VALUE other, VALUE rb_merge_alpha, VALUE rb_mode,
                               VALUE rb_src_x, VALUE rb_src_y, VALUE rb_src_w, VALUE rb_src_h,
                               VALUE rb_dst_x, VALUE rb_dst_y, VALUE rb_dst_w, VALUE rb_dst_h)
{
  rszr_image_handle * handle;
  rszr_image_handle * other_handle;
  Imlib_Operation operation;

  Check_Type(rb_mode,  T_FIXNUM);
  Check_Type(rb_src_x, T_FIXNUM);
  Check_Type(rb_src_y, T_FIXNUM);
  Check_Type(rb_src_w, T_FIXNUM);
  Check_Type(rb_src_h, T_FIXNUM);
  Check_Type(rb_dst_x, T_FIXNUM);
  Check_Type(rb_dst_y, T_FIXNUM);
  Check_Type(rb_dst_w, T_FIXNUM);
  Check_Type(rb_dst_h, T_FIXNUM);

  operation = (Imlib_Operation) NUM2INT(rb_mode);
  int src_x = NUM2INT(rb_src_x);
  int src_y = NUM2INT(rb_src_y);
  int src_w = NUM2INT(rb_src_w);
  int src_h = NUM2INT(rb_src_h);
  int dst_x = NUM2INT(rb_dst_x);
  int dst_y = NUM2INT(rb_dst_y);
  int dst_w = NUM2INT(rb_dst_w);
  int dst_h = NUM2INT(rb_dst_h);

  char merge_alpha = RTEST(rb_merge_alpha) ? 1 : 0;

  Data_Get_Struct(self, rszr_image_handle, handle);
  Data_Get_Struct(other, rszr_image_handle, other_handle);

  imlib_context_set_image(handle->image);
  imlib_context_set_operation(operation);
  imlib_blend_image_onto_image(other_handle->image, merge_alpha, src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h);

  return self;
}


static Imlib_Color_Range rszr_image_init_color_range(VALUE rb_gradient)
{
  Imlib_Color_Range range;
  VALUE rb_points;
  VALUE rb_point;
  VALUE rb_color;
  int size, i;
  double position;
  int red, green, blue, alpha;

  if(!rb_obj_is_kind_of(rb_gradient, cColorGradient)) {
    rb_raise(rb_eArgError, "color must be a Rszr::Color::Gradient");
  }

  rb_points = rb_funcall(rb_gradient, rb_intern("points"), 0);
  Check_Type(rb_points, T_ARRAY);

  imlib_context_get_color(&red, &green, &blue, &alpha);

  range = imlib_create_color_range();
  imlib_context_set_color_range(range);

  size = RARRAY_LEN(rb_points);
  for (i = 0; i < size; i++) {
    rb_point = rb_ary_entry(rb_points, i);
    if(!rb_obj_is_kind_of(rb_point, cColorPoint))
      rb_raise(rb_eArgError, "point must be a Rszr::Color::Point");

    rb_color = rb_funcall(rb_point, rb_intern("color"), 0);
    if(!rb_obj_is_kind_of(rb_color, cColorBase) || RBASIC_CLASS(rb_color) == cColorBase)
      rb_raise(rb_eArgError, "color must descend from Rszr::Color::Base");

    position = NUM2DBL(rb_funcall(rb_point, rb_intern("position"), 0));

    rszr_image_color_set(rb_color);
    imlib_add_color_to_color_range(position * 255);
  }

  imlib_context_set_color(red, green, blue, alpha);

  return range;
}


static VALUE rszr_image__rectangle_bang(VALUE self, VALUE rb_fill, VALUE rb_x, VALUE rb_y, VALUE rb_w, VALUE rb_h)
{
  rszr_image_handle * handle;
  VALUE rb_gradient;
  VALUE rb_color;
  Imlib_Color_Range range;
  double angle;

  Check_Type(rb_x, T_FIXNUM);
  Check_Type(rb_y, T_FIXNUM);
  Check_Type(rb_w, T_FIXNUM);
  Check_Type(rb_h, T_FIXNUM);

  int x = NUM2INT(rb_x);
  int y = NUM2INT(rb_y);
  int w = NUM2INT(rb_w);
  int h = NUM2INT(rb_h);

  rb_gradient = rb_funcall(rb_fill, rb_intern("gradient"), 0);
  rb_color = rb_funcall(rb_fill, rb_intern("color"), 0);
  
  Data_Get_Struct(self, rszr_image_handle, handle);
  imlib_context_set_image(handle->image);

  if (!NIL_P(rb_gradient)) {
    angle = NUM2DBL(rb_funcall(rb_fill, rb_intern("angle"), 0));
    range = rszr_image_init_color_range(rb_gradient);
    imlib_image_fill_color_range_rectangle(x, y, w, h, angle);
    imlib_free_color_range();
  } else if (!NIL_P(rb_color)) {
    rszr_image_color_set(rb_color);
    imlib_image_fill_rectangle(x, y, w, h);
  }

  return self;
}


static VALUE rszr_image__save(VALUE self, VALUE rb_path, VALUE rb_format, VALUE rb_quality, VALUE rb_interlace)
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

  imlib_image_remove_attached_data_value("interlacing");
  if (RTEST(rb_interlace))
    imlib_image_attach_data_value("interlacing", NULL, 1, NULL);

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

  cColorBase = rb_path2class("Rszr::Color::Base");
  cColorGradient = rb_path2class("Rszr::Color::Gradient");
  cColorPoint = rb_path2class("Rszr::Color::Point");
  cFill = rb_path2class("Rszr::Fill");

  rb_define_alloc_func(cImage, rszr_image_s_allocate);

  // Class methods
  rb_define_private_method(rb_singleton_class(cImage), "_load", rszr_image_s__load, 2);

  // Instance methods
  rb_define_method(cImage, "width",       rszr_image_width, 0);
  rb_define_method(cImage, "height",      rszr_image_height, 0);
  rb_define_method(cImage, "dup",         rszr_image_dup, 0);
  rb_define_method(cImage, "filter!",     rszr_image_filter_bang, 1);
  rb_define_method(cImage, "flop!",       rszr_image_flop_bang, 0);
  rb_define_method(cImage, "flip!",       rszr_image_flip_bang, 0);
  
  rb_define_method(cImage, "alpha",   rszr_image_alpha_get, 0);
  rb_define_method(cImage, "alpha=",  rszr_image_alpha_set, 1);
  
  rb_define_protected_method(cImage, "_format",  rszr_image__format_get, 0);
  rb_define_protected_method(cImage, "_format=", rszr_image__format_set, 1);

  rb_define_private_method(cImage, "_initialize",   rszr_image__initialize, 2);
  rb_define_private_method(cImage, "_resize",       rszr_image__resize, 7);
  rb_define_private_method(cImage, "_crop",         rszr_image__crop, 5);
  rb_define_private_method(cImage, "_turn!",        rszr_image__turn_bang, 1);
  rb_define_private_method(cImage, "_rotate",       rszr_image__rotate, 2);
  rb_define_private_method(cImage, "_sharpen!",     rszr_image__sharpen_bang, 1);
  rb_define_private_method(cImage, "_desaturate!",  rszr_image__desaturate_bang, 1);
  rb_define_private_method(cImage, "_pixel",        rszr_image__pixel_get, 2);
  rb_define_private_method(cImage, "_blend",        rszr_image__blend, 11);
  rb_define_private_method(cImage, "_rectangle!",   rszr_image__rectangle_bang, 5);

  rb_define_private_method(cImage, "_save",       rszr_image__save, 4);
}

#endif
