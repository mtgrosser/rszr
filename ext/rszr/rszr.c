#ifndef RUBY_RSZR
#define RUBY_RSZR

#include "rszr.h"
#include "image.h"
#include "errors.h"

VALUE mRszr = Qnil;

void Init_rszr()
{
    mRszr = rb_define_module("Rszr");
    Init_rszr_errors();
    Init_rszr_image();
}

#endif
