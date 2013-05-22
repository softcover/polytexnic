# encoding=utf-8
require 'polytexnic-core/literal'
require 'polytexnic-core/html'

module Polytexnic
  module Preprocessor
    include Literal
    include Html

    # Preprocesses the input PolyTeX based on output format.
    def preprocess(format)
      if format == :html
        to_xml
      elsif format == :latex
        to_hashed_latex
      end
    end

    # Returns LaTeX with hashed versions of verbatim environments.
    def to_hashed_latex
      highlight(@polytex)
    end

  private

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
