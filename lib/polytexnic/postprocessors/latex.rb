require 'polytexnic/literal'

module Polytexnic
  module Postprocessor
    module Latex

      # Restores literal environments (verbatim, code, math, etc.).
      def replace_hashes(polytex)
        puts polytex if debug?
        polytex.tap do
          literal_cache.each do |key, value|
            puts value.inspect if debug?
            polytex.gsub!(key, extra_escape(escape_backslashes(value)))
          end
        end
      end

      # Escapes backslashes even more.
      # Have I mentioned how much I hate backslashes?
      def extra_escape(string)
        string.gsub('\\', '\\\\\\')
      end
    end
  end
end
