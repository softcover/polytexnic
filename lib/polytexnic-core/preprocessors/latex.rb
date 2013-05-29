module Polytexnic
  module Preprocessor
    module Latex

      # Returns LaTeX with hashed versions of verbatim environments.
      def to_hashed_latex
        @polytex = make_caches(@polytex, :latex)
      end
    end
  end
end
