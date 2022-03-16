source 'https://rubygems.org'

# Include a bunch of language encoding settings.
LANG="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

gemspec

group :test do
  gem 'coveralls', require: false
  gem 'growl'
end

group :development do
  gem 'guard-rspec', require: false
  gem 'rake'
end
