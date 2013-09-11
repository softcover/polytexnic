module Polytexnic
  module Literal

    # Matches the line for syntax highlighting.
    LANG_REGEX = /^\s*%=\s+lang:(\w+)/

    # Makes the caches for literal environments.
    def cache_literal(polytex, format = :html)
      output = []
      lines = polytex.split("\n")
      cache_literal_environments(lines, output, format)
      output = output.join("\n")
      if format == :html
        cache_display_math(output)
        cache_inline_math(output)
      end
      output
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
    #
    # The control flow here is really nasty, but attempts to refactor it
    # into a multi-pass solution have only resulted in even more complexity,
    # and even then I've failed to get it to work. Thus, it shall for now
    # follow the "ball of mud" pattern.
    def cache_literal_environments(lines, output, format)
      latex = (format == :latex)
      language = nil
      in_verbatim = false
      while (line = lines.shift)
        if line =~ LANG_REGEX && !in_verbatim
          language = $1
        elsif line.begin_literal?
          in_verbatim = true
          literal_type = line.literal_type
          skip = line.math_environment? || latex
          if line.math_environment? && !latex
            output << '\begin{xmlelement*}{equation}'
            output << '\begin{equation}'
          end
          math = line.math_environment?
          label = nil
          output << xmlelement(element(literal_type), skip) do
            count = 1
            text = []
            text << line if line.math_environment? || (latex && !language)
            while (line = lines.shift)
              if line.begin_literal?(literal_type)
                count += 1
              elsif line.end_literal?(literal_type)
                count -= 1
                if count.zero?
                  in_verbatim = false
                  text << line if line.math_environment? ||
                                  (latex && !language)   ||
                                  (latex && math)
                  break
                end
              end
              label = line if math && line =~ /^\s*\\label{.*?}\s*$/
              text << line
            end
            raise "Missing \\end{#{line.literal_type}}" if count != 0
            content = text.join("\n")
            key = digest(content)
            if math
              literal_cache[key] = content
            elsif language.nil?
              literal_cache[key] = content
              tag = 'literal'
            else
              code_cache[key] = [content, language]
              tag = 'code'
            end
            if latex || tag == 'code' || math
              key
            else
              xmlelement(tag) { key }
            end
          end
          if math && !latex
            unless label.nil?
              key = digest(label)
              math_label_cache[key] = label
              output << key
            end
            output << '\end{equation}'
            unless label.nil?
              string = label.scan(/\{(.*?)\}/).flatten.first
              string = string.gsub(':', '-').gsub('_', underscore_digest)
              output << "\\xbox{data-label}{#{string}}"
            end
            output << '\end{xmlelement*}'
          end
          language = nil
          (output << '') unless latex # Force the next element to be a paragraph
        else
          output << line
        end
      end
    end

    # Caches display math.
    # We support both TeX-style $$...$$ and LaTeX-style \[ ... \].
    def cache_display_math(output)
      output.gsub!(/\\\[(.*?)\\\]|\$\$(.*?)\$\$/m) do
        math = "\\[ #{$1 || $2} \\]"
        equation_element(math)
      end
    end

    # Returns an equation element while caching the given content.
    def equation_element(content)
      key = digest(content)
      literal_cache[key] = content
      "\\begin{xmlelement*}{equation}
        \\begin{equation}
        #{key}
        \\end{equation}
        \\end{xmlelement*}"
    end

    # Caches inline math.
    # We support both TeX-style $...$ and LaTeX-style \( ... \).
    # There's an annoying edge case involving literal dollar signs, as in \$.
    # Handling it significantly complicates the regex, and necessesitates
    # introducing an additional group to catch the character before the math
    # dollar sign in $2 and prepend it to the inline math element.
    def cache_inline_math(output)
      output.gsub!(/(?:\\\((.*?)\\\)|([^\\]|^)\$(.*?[^\\])\$)/m) do
        math = "\\( #{$1 || $3} \\)"
        key = digest(math)
        literal_cache[key] = math
        $2.to_s + xmlelement('inline') { key }
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
    def hyperrefs(string)
      linked_item = "(Chapter|Section|Table|Box|Figure|Fig\.|Listing" +
                    "|Equation|Eq\.)"
      ref = /(?:#{linked_item}(~| ))*(\\(?:eq)*ref){(.*?)}/i
      string.gsub!(ref) do
        "\\hyperref[#{$4}]{#{$1}#{$2}#{$3}{#{$4}}}"
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
  %w{align align*
     eqnarray eqnarray* equation equation*
     gather gather* gathered
     multline multline*
    }
end

class String

  def begin_verbatim?
    literal_type = "(?:verbatim|Verbatim|code|metacode)"
    match(/^\s*\\begin{#{literal_type}}\s*$/)
  end

  # Returns true if self matches \begin{...} where ... is a literal environment.
  # Support for the 'metacode' environment exists solely to allow
  # meta-dicsussion of the 'code' environment.
  def begin_literal?(literal_type = nil)
    literal_type ||= "(?:verbatim|Verbatim|code|metacode|#{math_environment_regex})"
    match(/^\s*\\begin{#{literal_type}}\s*$/)
  end

  def end_literal?(literal_type)
    match(/^\s*\\end{#{Regexp.escape(literal_type)}}\s*$/)
  end

  # Returns the type of literal environment.
  # '\begin{verbatim}' => 'verbatim'
  # '\begin{equation}' => 'equation'
  # '\[' => 'display'
  def literal_type
    scan(/\\begin{(.*?)}/).flatten.first || 'display'
  end

  def begin_math?
    literal_type = "(?:#{math_environment_regex})"
    match(/^\s*\\begin{#{literal_type}}\s*$/)
  end

  def math_environment?
    match(/(?:#{math_environment_regex})/)
  end

  private

    def math_environment_regex
      math_environments.map { |s| Regexp.escape(s) }.join('|')
    end
end