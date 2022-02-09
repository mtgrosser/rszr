require 'mkmf'
require 'rbconfig'

pkg_config('imlib2')

$CFLAGS << ' -DX_DISPLAY_MISSING'
$LDFLAGS.gsub!(/\ -lX11\ -lXext/, '') if RUBY_PLATFORM =~ /darwin/

unless find_header('Imlib2.h')
  abort 'imlib2 development headers are missing'
end

unless find_library('Imlib2', 'imlib_set_cache_size')
  abort 'Imlib2 is missing'
end

create_makefile 'rszr/rszr'
