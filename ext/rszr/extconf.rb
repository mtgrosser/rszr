require 'mkmf'
require 'rbconfig'

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

create_makefile 'rszr/rszr'
