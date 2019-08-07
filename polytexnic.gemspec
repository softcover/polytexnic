# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polytexnic/version'

Gem::Specification.new do |gem|
  gem.name          = "polytexnic"
  gem.version       = Polytexnic::VERSION
  gem.authors       = ["Michael Hartl", "Nick Merwin"]
  gem.email         = ["michael@softcover.io"]
  gem.description   = %q{Core translation engine for the polytexnic gem}
  gem.summary       = %q{Convert from PolyTeX & Markdown to HTML & LaTeX}
  gem.homepage      = "https://polytexnic.org/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'nokogiri', '~> 1.8'
  gem.add_dependency 'pygments.rb', '~> 1.2.1'
  gem.add_dependency 'msgpack', '~> 1.2.0'
  gem.add_dependency 'kramdown', '~> 1.17'
  gem.add_dependency 'json', '~> 1.8.1'

  gem.add_development_dependency 'rspec', '~> 2.14'
  gem.add_development_dependency 'simplecov', '~> 0.15.1'
end
