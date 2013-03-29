# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polytexnic-core/version'

Gem::Specification.new do |gem|
  gem.name          = "polytexnic-core"
  gem.version       = Polytexnic::Core::VERSION
  gem.authors       = ["Michael Hartl", "Nick Merwin"]
  gem.email         = ["michael@michaelhartl.com"]
  gem.description   = %q{Translation to and from PolyTeX}
  gem.summary       = %q{Provide utilities for converting PolyTeX
                         to HTML and LaTeX, and from Markdown to PolyTeX}
  gem.homepage      = "https://github.com/mhartl/polytexnic-core"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
