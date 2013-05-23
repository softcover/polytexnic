module Polytexnic
  module Literal

    # Makes the caches for literal environments (including non-ASCII Unicode).
    def make_caches(polytex, format = :html)
      output = []
      lines = polytex.split("\n")
      cache_literal_environments(lines, output, format)
      output.join("\n")
    end

    # Handles environments that should be passed through the pipeline intact.
    # The includes verbatim environments ('verbatim', 'Verbatim') and all the
    # equation environments handled by MathJax ('equation', 'align', etc.).
    # We take care to keep count of the number of begins we see so that the
    # code handles nested environments correctly; i.e.,
    #   \begin{verbatim}
    #     \begin{verbatim}
    #     \emph{foo bar}
    #     \end{verbatim}
    #   \end{verbatim}
    #   lorem ipsum
    # gets includes the internal literal text without stopping after the first
    # \end{verbatim}.
    def cache_literal_environments(lines, output, format)
      latex = format == :latex
      language = nil
      while (line = lines.shift)
        if line =~ /%=\s+lang:(\w+)/
          if latex
            output << line
          else
            language = $1
          end
        elsif line.begin_literal?
          literal_type = line.literal_type
          output << xmlelement(element(literal_type), latex) do
            count = 1
            text = []
            text << line if line.math_environment? || latex
            while (line = lines.shift)
              if line.begin_literal?
                count += 1
              elsif line.end_literal?(literal_type)
                count -= 1
                if count == 0
                  text << line if line.math_environment? || latex
                  break
                end
              end
              text << line
            end
            raise "Missing \\end{#{line.literal_type}}" if count != 0
            content = text.join("\n")
            key = digest(content)
            if latex
              literal_cache[key] = content
              key
            else
              if language.nil?
                literal_cache[key] = content
                tag = 'literal'
              else
                code_cache[key] = [content, language]
                tag = 'code'
              end
              xmlelement(tag) { key }
            end
          end
          language = nil
          (output << '') unless latex # Force the next element to be a paragraph
        else
          output << line
        end
      end
    end

    # Converts references to hyperrefs.
    # We want to convert 
    #   Chapter~\ref{cha:foo}
    # to
    #   \hyperref[cha:foo]{Chapter~\ref{cha:foo}
    # which is then handled by LaTeX's hyperref package
    # or by Tralics (where it converted to a link
    # by the postprocessor).
    # For completeness, we handle the case where the author neglects to
    # use the nonbreak space ~.
    def hyperref(string)
      linked_item = "(Chapter|Section|Table|Box|Figure|Listing)"
      ref = /#{linked_item}(~| )\\ref{(.*?)}/
      string.gsub(ref) do
        "\\hyperref[#{$3}]{#{$1}#{$2}\\ref{#{$3}}}"
      end
    end

    # Handles non-ASCII Unicode characters.
    # The Tralics part of the pipeline doesn't properly handle Unicode,
    # which is odd since Tralics is a French project. Nevertheless,
    # we can hack around the restriction by treating non-ASCII Unicode
    # characters as literal elements and simply pass them through the
    # pipeline intact.
    def cache_unicode(string)
      non_ascii_unicode = /([^\x00-\x7F]+)/
      string.gsub(non_ascii_unicode) do
        key = digest($1)
        literal_cache[key] = $1
        xmlelement('unicode') { key }
      end
    end

    def element(literal_type)
      if math_environments.include?(literal_type)
        'equation'
      else
        literal_type
      end
    end
  end
end

# Returns supported math environments.
# Note that the custom AMSTeX environments are supported
# in addition to the LaTeX defaults.
def math_environments
  %w[align align* alignat alignat* array
     Bmatrix bmatrix cases
     eqnarray eqnarray* equation equation*
     gather gather* gathered
     matrix multline multline*
     pmatrix smallmatrix split subarray
     Vmatrix vmatrix
    ]
end

class String

  # Returns true if self matches \begin{...} where ... is a literal environment.
  def begin_literal?
    literal = "(?:verbatim|Verbatim|code|#{math_environment_regex})"
    match(/^\s*\\begin{#{literal}}\s*$/)
  end

  def end_literal?(literal_type)
    match(/^\s*\\end{#{Regexp.escape(literal_type)}}\s*$/)
  end

  # Returns the type of literal environment.
  # '\begin{verbatim}' => 'verbatim'
  # '\begin{equation}' => 'equation'
  def literal_type
    scan(/\\begin{(.*?)}/).flatten.first
  end

  def math_environment?
    match(/(?:#{math_environment_regex})/)
  end

  private

    def math_environment_regex
      math_environments.map { |s| Regexp.escape(s) }.join('|')
    end
end