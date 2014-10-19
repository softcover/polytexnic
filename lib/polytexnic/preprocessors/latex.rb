module Polytexnic
  module Preprocessor
    module Latex

      def to_processed_latex
        @polytex = convert_gifs(
                     polish_tables(
                     process_asides(clean_latex_document)))
      end

      # Returns LaTeX with hashed versions of literal environments.
      # Literal environments are hashed and passed through the pipeline
      # so that we can process things like refs and hyperrefs using gsubs.
      def clean_latex_document
        cache_literal(@polytex, :latex).tap do |doc|
          expand_input!(doc,
                        Proc.new { |source| cache_literal(source, :latex) },
                        'tex')
        end
      end

      # Convert GIFs to PNGs.
      # Unfortunately, xelatex doesn't support GIFs. This converts the included
      # filenames to use '.png' in place of '.gif'. When used with the Softcover
      # system, the correct PNG files are automatically created on the fly.
      def convert_gifs(text)
        text.tap do
          text.gsub!(/\\(includegraphics|image|imagebox)\{(.*)\.gif\}/) do
            "\\#{$1}{#{$2}.png}"
          end
        end
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
        # Transform asides with labels and headings.
        aside_regex = /\\begin{aside}\n\s*
                       \\label{(.*?)}\s*
                       \\heading{(.*?)}\n
                       (.*?)
                       \\end{aside}/mx
        text.tap do
          text.gsub!(aside_regex) do
            %(\\begin{shaded_aside}{#{$2}}{#{$1}}\n#{$3}\n\\end{shaded_aside})
          end
        end
      end
    end
  end
end
