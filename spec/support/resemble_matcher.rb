RSpec::Matchers.define :resemble do |expected|
  match do |actual|
    if expected.is_a?(String)
      regex = Regexp.escape(expected.compress)
    elsif expected.is_a?(Regexp)
      regex = %r{#{expected.to_s.compress}}
    end
    expect(actual.compress).to match_regex(regex)
  end
end

class String

  # Compress whitespace
  # Eliminates repeating whitespace (spaces or tabs)
  # >> "foo\t    bar\n\nbaz    quux\nderp".compress
  # => "foo bar\n\nbaz quux\nderp"
  def compress
    self.strip.gsub(/[ \t]{2,}/, ' ')
  end

  def compress!
    replace(self.compress)
  end
end