require 'polytexnic-core/literal'

module Polytexnic
  module Postprocessor
    module Latex

      # Restores literal environments (verbatim, code, math, etc.).
      def replace_hashes(polytex)
        polytex.tap do
          literal_cache.each do |key, value|
            polytex.gsub!(key, escape_backslashes(value))
          end
        end
      end
    end
  end
end
