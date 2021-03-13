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

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rake-compiler'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'image_processing'
  s.add_development_dependency 'gd2-ffij'
  s.add_development_dependency 'mini_magick'
  s.add_development_dependency 'ruby-vips'
  s.add_development_dependency 'memory_profiler'
end
