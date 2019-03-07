#ifndef RUBY_RSZR_ERRORS
#define RUBY_RSZR_ERRORS

#include "rszr.h"
#include "errors.h"

VALUE eRszrError = Qnil;
VALUE eRszrFileNotFound = Qnil;
VALUE eRszrTransformationError = Qnil;
VALUE eRszrErrorWithMessage = Qnil;
VALUE eRszrLoadError = Qnil;
VALUE eRszrSaveError = Qnil;

static const char * const sRszrErrorMessages[] =
{
  "File does not exist",
  "File is a directory",
  "Read permission denied",
  "Unsupported format",
  "Path too long",
  "Non-existant path component",
  "Path component is not a directory",
  "Path outside address space",
  "Too many symbolic links",
  "Out of memory",
  "Out of file descriptors",
  "Write permission denied",
  "Out of disk space",
  "Unknown error"
};
const int RSZR_MAX_ERROR_INDEX = 13;

void Init_rszr_errors()
{
  eRszrError = rb_define_class_under(mRszr, "Error", rb_eStandardError);
  eRszrFileNotFound = rb_define_class_under(mRszr, "FileNotFound", eRszrError);
  eRszrTransformationError = rb_define_class_under(mRszr, "TransformationError", eRszrError);
  eRszrErrorWithMessage = rb_define_class_under(mRszr, "ErrorWithMessage", eRszrError);
  eRszrLoadError = rb_define_class_under(mRszr, "LoadError", eRszrErrorWithMessage);
  eRszrSaveError = rb_define_class_under(mRszr, "SaveError", eRszrErrorWithMessage);
}

static void rszr_raise_error_with_message(VALUE rb_error_class, Imlib_Load_Error error)
{
  int error_index = (int) error - 1;
  if (error_index < 1 || error_index > RSZR_MAX_ERROR_INDEX)
    error_index = 13;
  VALUE rb_error = rb_exc_new2(rb_error_class, sRszrErrorMessages[error_index]);
  rb_exc_raise(rb_error);
}

void rszr_raise_load_error(Imlib_Load_Error error)
{
  rszr_raise_error_with_message(eRszrLoadError, error);
}

void rszr_raise_save_error(Imlib_Load_Error error)
{
  rszr_raise_error_with_message(eRszrSaveError, error);
}


#endif