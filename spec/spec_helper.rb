require 'simplecov'
require 'json'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter])
SimpleCov.start

require 'polytexnic'

# Load support files.
Dir.glob(File.join(File.dirname(__FILE__), "./support/**/*.rb")).each do |f|
  require_relative(f)
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  Polytexnic::Utils.set_test_mode!
  config.before do
    Polytexnic::Utils.set_test_mode!
  end

  # Disallow the old-style 'object.should' syntax.
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
