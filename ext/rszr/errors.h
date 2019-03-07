#ifndef RUBY_RSZR_ERRORS_H
#define RUBY_RSZR_ERRORS_H

void Init_rszr_errors();
void rszr_raise_load_error(Imlib_Load_Error error);
void rszr_raise_save_error(Imlib_Load_Error error);

extern VALUE eRszrError;
extern VALUE eRszrFileNotFound;
extern VALUE eRszrTransformationError;
extern VALUE eRszrErrorWithMessage;
extern VALUE eRszrLoadError;
extern VALUE eRszrSaveError;

#endif
