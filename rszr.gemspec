# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rszr/version'

Gem::Specification.new do |spec|
  spec.name          = "rszr"
  spec.version       = Rszr::VERSION
  spec.authors       = ["Matthias Grosser"]
  spec.email         = ["mtgrosser@gmx.net"]

  spec.summary       = %q{Fast image resizer}
  spec.description   = %q{Rszr was created to do one thing and do it fast}
  spec.homepage      = "https://github.com/mtgrosser/rszr"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
