# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'attr_permit/version'

Gem::Specification.new do |spec|
  spec.name          = "attr_permit"
  spec.version       = AttrPermit::VERSION
  spec.authors       = ["Dustin Zeisler"]
  spec.email         = ["dustin@zive.me"]
  spec.summary       = %q{Simple parametable object creator with lazy loading options.}
  spec.description   = %q{Simple parametable object creator with lazy loading options. Objects can be hashable and optionally convert all values to strings.}
  spec.homepage      = "https://github.com/zeisler/attr_permit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "virtus", '~> 1.0'
  spec.add_runtime_dependency "activesupport", ">= 4.0"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.3"
  spec.add_development_dependency "rspec", "~>3.0"
end
