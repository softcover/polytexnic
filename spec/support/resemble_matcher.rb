# encoding=utf-8
require 'polytexnic'

RSpec::Matchers.define :resemble do |expected|
  match do |actual|
    if expected.is_a?(String)
      regex = %r{#{Regexp.escape(expected.robust)}}
    elsif expected.is_a?(Regexp)
      regex = %r{#{expected.to_s.robust}}
    end

    failure_message_for_should do |actual|
      debug_output(expected, actual)
      "expected #{actual} to resemble #{expected}"
    end

    failure_message_for_should_not do |actual|
      debug_output(expected, actual)
      "expected #{actual} not to resemble #{expected}"
    end

    expect(actual.robust).to match_regex(regex)
  end
end

def debug_output(expected, actual)
  print_output expected, actual if Polytexnic::Utils.debug?
end

# Prints the robust versions of the two strings
# The output is hugely useful in visually diffing, e.g., HTML output.
def print_output(expected, actual)
  puts "expect: " + expected.robust
  puts "actual: " + actual.robust
end

class String

  # Prepares a string for robust comparison.
  def robust
    apply_character_equivalences.compress.remove_tag_whitespace
  end

  # Applies UTF-8 character code equivalences.
  # For example, '&#133;' and '…' are the same character (horizontal ellipsis),
  # and depending on the version of Ruby and other factors the string might
  # contain either or both.
  # We want to be robust to the differences, to gsub them out.
  # For clarity, we standardize on the characters that look literally correct,
  # e.g., '…'.
  # Rather than be exhaustive, we of course only check the ones actually
  # used in the tests. Browsers, etc., display them the same.
  def apply_character_equivalences
    equivalences = [ ['&#8216;', '‘'],
                     ['&#8217;', '’'],
                     ['&#8220;', '“'],
                     ['&#8221;', '”'],
                     ['&#160;',  ' '],     # nonbreaking space
                     ['&thinsp;',' '],     # thin space
                     ['&#133;',  '…'],
                     ['&#8230;', '…'],
                     ['&#8617',  '↩']
                   ]
    tap do
      equivalences.each do |code, character|
        gsub!(code, character)
      end
    end
  end

  def remove_tag_whitespace
    gsub(/\s*</, '<').gsub(/>\s*/, '>')
  end

  # Compress whitespace
  # Eliminates repeating whitespace (spaces, tabs, or Unicode nbsp),
  # converting everthing to ordinary spaces, while stripping leading
  # and trailing whitespace.
  # >> "foo\t    bar\n\nbaz    quux\nderp".compress
  # => "foo bar baz quux derp"
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
    stripped_result.gsub("\n", ' ').gsub(/[ \t]{2,}/, ' ')
  end
end