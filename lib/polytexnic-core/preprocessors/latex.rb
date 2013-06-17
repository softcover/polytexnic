module Polytexnic
  module Preprocessor
    module Latex

      # Returns LaTeX with hashed versions of literal environments.
      # Literal environments are hashed and passed through the pipeline
      # so that we can process things like refs to hyperrefs using gsubs.
      def to_hashed_latex
        @polytex = make_caches(@polytex, :latex)
      end
    end
  end
end
