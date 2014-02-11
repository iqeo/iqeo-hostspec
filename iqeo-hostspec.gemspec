# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'iqeo/hostspec'

Gem::Specification.new do |spec|

  spec.name          = "iqeo-hostspec"
  spec.version       = Iqeo::Hostspec::VERSION
  spec.authors       = ["Gerard Fowley"]
  spec.email         = ["gerard.fowley@iqeo.net"]
  spec.description   = %q{Write a gem description}
  spec.summary       = %q{Write a gem summary}
  spec.homepage      = ""
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"

end
