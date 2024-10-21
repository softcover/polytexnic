# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'polytexnic/version'

Gem::Specification.new do |gem|
  gem.name          = "polytexnic"
  gem.version       = Polytexnic::VERSION
  gem.authors       = ["Michael Hartl", "Nick Merwin"]
  gem.email         = ["michael@softcover.io"]
  gem.description   = %q{Core translation engine for the softcover gem}
  gem.summary       = %q{Convert from PolyTeX & Markdown to HTML & LaTeX}
  gem.homepage      = "https://github.com/softcover/polytexnic"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'nokogiri', '1.15.2'
  gem.add_dependency 'pygments.rb', '~> 2.3.1'
  gem.add_dependency 'msgpack', '1.7.2'
  gem.add_dependency 'kramdown', '2.4.0'
  gem.add_dependency 'json', '2.7.2'

  gem.add_development_dependency 'rspec', '2.99.0'
  gem.add_development_dependency 'simplecov', '0.15.1'
end
