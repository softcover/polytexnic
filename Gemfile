source 'https://rubygems.org'

gem 'rspec', '~> 2.13'
gem 'nokogiri', '~> 1.5.0'
gem 'pygments.rb', "~> 0.4.2"

# Specify your gem's dependencies in polytexnic-core.gemspec
gemspec

group :test do
  gem 'debugger2' unless RUBY_VERSION < "2.0"
  gem 'coveralls', require: false
end