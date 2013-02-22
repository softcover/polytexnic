# encoding=utf-8

RSpec::Matchers.define :resemble do |expected|
  match do |actual|
    regex = Regexp.new begin
      if expected.is_a?(String)
        Regexp.escape(expected.compress)
      elsif expected.is_a?(Regexp)
        expected.to_s.compress
      else
        raise "resemble matcher requires String or Regexp"
      end
    end

    actual.compress =~ regex
  end
end

class String

  # Compress whitespace
  # Eliminates repeating whitespace (spaces, tabs, or Unicode nbsp),
  # converting everthing to ordinary spaces, while stripping leading
  # and trailing whitespace.
  # >> "foo\t    bar\n\nbaz    quux\nderp".compress
  # => "foo bar\n\nbaz quux\nderp"
  # 
  # Spaces surround each line are stripped entirely, so that
  #   <ul>
  #     <li>alpha</li>
  #     <li>bravo</li>
  #     <li>charlie</li>
  #   </ul>
  # becomes
  # <ul>
  # <li>alpha</li>
  # <li>bravo</li>
  # <li>charlie</li>
  # </ul>  
  def compress
    unicode_nbsp = ' '
    result = gsub(unicode_nbsp, ' ')
    stripped_result = result.split("\n").map(&:strip).join("\n")
    stripped_result.gsub(/[ \t]{2,}/, ' ')
  end

  def compress!
    replace(self.compress)
  end
end