# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rszr/version'

Gem::Specification.new do |s|
  s.name          = "rszr"
  s.version       = Rszr::VERSION
  s.authors       = ["Matthias Grosser"]
  s.email         = ["mtgrosser@gmx.net"]

  s.summary       = %q{Fast image resizer}
  s.description   = %q{Rszr was created to do one thing and do it fast}
  s.homepage      = "https://github.com/mtgrosser/rszr"

  s.files         = Dir['{lib}/**/*.rb', 'LICENSE', 'README.md', 'Rakefile']
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.9"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "byebug"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "gd2-ffij"
  s.add_development_dependency "mini_magick"
end
