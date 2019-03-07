require 'mkmf'
require 'rbconfig'
=begin
LIBDIR      = RbConfig::CONFIG['libdir']
INCLUDEDIR  = RbConfig::CONFIG['includedir']

HEADER_DIRS = [
  '/opt/local/include',
  '/usr/local/include',
  INCLUDEDIR,
  '/usr/include',
]

LIB_DIRS = [
  '/opt/local/lib',
  '/usr/local/lib',
  LIBDIR,
  '/usr/lib',
]

dir_config('Imlib2', HEADER_DIRS, LIB_DIRS)
=end
imlib2_config = with_config('imlib2-config', 'imlib2-config')

$CFLAGS << ' -DX_DISPLAY_MISSING ' << `#{imlib2_config} --cflags`.chomp
$LDFLAGS << ' ' << `#{imlib2_config} --libs`.chomp
$LDFLAGS.gsub!(/\ -lX11\ -lXext/, '') if RUBY_PLATFORM =~ /darwin/

unless find_header('Imlib2.h')
  abort 'imlib2 development headers are missing'
end

unless find_library('Imlib2', 'imlib_set_cache_size')
  abort 'Imlib2 is missing'
end

create_makefile 'rszr'
