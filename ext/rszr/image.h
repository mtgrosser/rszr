#ifndef RUBY_RSZR_IMAGE_H
#define RUBY_RSZR_IMAGE_H

typedef struct {
  Imlib_Image image;
} rszr_image_handle;

typedef struct {
  uint8_t blue, green, red, alpha; //alpha, red, green, blue;
} rszr_raw_pixel;

extern VALUE cImage;

void Init_rszr_image();

#endif
