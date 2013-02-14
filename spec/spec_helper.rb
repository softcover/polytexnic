require 'polytexnic-core'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

RSpec::Matchers.define :resemble do |expected|
  match do |actual|
    expect(actual.compress).to match_regex(expected.to_s.compress)
  end
end

class String

  # Compress whitespace
  # Eliminates repeating whitespace (apart from newlines)
  # >> "foo\t    bar\n\nbaz    quux\nderp".compress
  # => "foo bar\n\nbaz quux\nderp"
  def compress
    self.strip.gsub(/[ \t]{2,}/, ' ')
  end

  def compress!
    replace(self.compress)
  end

end