module Polytexnic
  module Preprocessor
    module Latex

      def to_processed_latex
        @polytex = polish_tables(process_asides(clean_latex_document))
      end

      # Returns LaTeX with hashed versions of literal environments.
      # Literal environments are hashed and passed through the pipeline
      # so that we can process things like refs to hyperrefs using gsubs.
      def clean_latex_document
        cache_literal(@polytex, :latex)
      end

      def polish_tables(text)
        text.tap do
          text.gsub!(/^\s*(\\begin\{table\})/) do
            "#{$1}\n\\begin{center}\n\\small\n"
          end
          text.gsub!(/^\s*(\\end\{table\})/) { "\\end{center}\n#{$1}" }
        end
      end

      # Processes aside environments.
      # In order to get nice framed & shaded aside boxes, we need to
      # transform the default aside into a new environment.
      def process_asides(text)
        # Transform asides with headings and labels.
        aside_regex = /\\begin{aside}\n\s*
                       \\heading{(.*?)}\s*
                       \\label{(.*?)}\n
                       (.*?)
                       \\end{aside}/mx
        text.tap do
          text.gsub!(aside_regex) do
            %(\\begin{shaded_aside}{#{$1}}{#{$2}}\n#{$3}\n\\end{shaded_aside})
          end
        end
      end
    end
  end
end
