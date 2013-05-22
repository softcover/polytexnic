module Polytexnic
  module Postprocessor
    module Latex

      # Restores literal environments (verbatim, code, math, etc.).
      # These environments are hashed and passed through the pipeline
      # so that we can process things like refs to hyperrefs using gsubs.
      def replace_hashes(polytex)
        literal_cache.each do |key, value|
          polytex.gsub!(key, escape_backslashes(value))
        end
        polytex
      end

      # Replaces code listings with highlighted versions.
      def highlight(latex)
        lines = latex.split("\n")
        output = []
        while (line = lines.shift) do
          if line =~ /%=\s+lang:(\w+)/
            language = $1
            count = 0
            code = []
            while (line = lines.shift) do
              if line =~ /^\s*\\begin{code}\s*$/
                count += 1
              elsif line =~ /^\s*\\end{code}\s*/
                count -= 1
                if count == 0
                  output << Pygments.highlight(code.join("\n"),
                                               lexer: language,
                                               formatter: 'latex')
                  break
                end
              else
                code << line
              end
            end
          else
            output << line
          end
        end
        output.join("\n")
      end
    end
  end
end
