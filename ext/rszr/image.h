#ifndef RUBY_RSZR_IMAGE_H
#define RUBY_RSZR_IMAGE_H

typedef struct {
  Imlib_Image image;
} rszr_image_handle;

extern VALUE cImage;

void Init_rszr_image();

#endif
