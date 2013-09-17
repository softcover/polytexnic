source 'https://rubygems.org'

gemspec

group :test do
  gem 'debugger2' unless RUBY_VERSION < "2.0"
  gem 'coveralls', require: false
  gem 'growl'
end

group :development do
  gem 'rspec', '~> 2.13'
  gem 'guard-rspec'
  gem 'rake'
end