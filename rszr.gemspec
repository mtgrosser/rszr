lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rszr/version'

Gem::Specification.new do |s|
  s.name          = 'rszr'
  s.version       = Rszr::VERSION
  s.authors       = ['Matthias Grosser']
  s.email         = ['mtgrosser@gmx.net']

  s.summary       = %q{Fast image resizer}
  s.description   = %q{Fast image resizer - do one thing and do it fast.}
  s.licenses      = %w[MIT]
  s.homepage      = 'https://github.com/mtgrosser/rszr'

  s.files         = Dir['{lib,ext}/**/*.{rb,h,c}', 'LICENSE', 'README.md', 'Rakefile']
  s.require_paths = %w[lib ext]
  s.extensions    = %w[ext/rszr/extconf.rb]

  s.requirements  = %w[imlib2 libexif]
end
