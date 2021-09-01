module Polytexnic
  module Literal
    extend self

    # Matches the line for syntax highlighting.
    # %= lang: <language>[, options: ...]
    LANG_REGEX = /^\s*%=\s+lang:\s*([\w+]+)(?:,\s*options:(.*))?/


    # Makes the caches for literal environments.
    def cache_literal(polytex, format = :html)
      output = []
      lines = polytex.split("\n")
      cache_literal_environments(lines, output, format)
      output.join("\n")
    end

    # Returns supported math environments.
    # Note that the custom AMS-TeX environments are supported
    # in addition to the LaTeX defaults.
    def math_environments
      %w[align align*
         eqnarray eqnarray* equation equation*
         gather gather* gathered
         multline multline*
        ]
    end

    # Returns a list of all literal types.
    def literal_types
      %w[verbatim Vertatim code metacode] + math_environments
    end

    # Handles environments that should be passed through the pipeline intact.
    # The includes verbatim environments ('verbatim', 'Verbatim') and all the
    # equation environments handled by MathJax ('equation', 'align', etc.).
    # We take care to keep count of the number of begins we see so that the
    # code handles nested environments correctly. I.e.,
    #   \begin{verbatim}
    #     \begin{verbatim}
    #     \emph{foo bar}
    #     \end{verbatim}
    #   \end{verbatim}
    #   lorem ipsum
    # includes the internal literal text without stopping after the first
    # \end{verbatim}.
    #
    # The control flow here is really nasty, but attempts to refactor it
    # into a multi-pass solution have only resulted in even more complexity,
    # and even then I've failed to get it to work. Thus, it shall for now
    # follow the "ball of mud" pattern. (The only saving grace is that it's
    # very thoroughly tested.)
    def cache_literal_environments(lines, output, format, cache = nil)
      latex = (format == :latex)
      language = nil
      in_verbatim = false
      in_codelisting = false
      while (line = lines.shift)
        if line =~ LANG_REGEX && !in_verbatim
          language = $1
          highlight_options = $2
        elsif line =~ /\s*\\begin\{codelisting\}/ && !in_verbatim
          in_codelisting = true
          output << line
        elsif line =~ /\s*\\end\{codelisting\}/ && !in_verbatim
          in_codelisting = false
          output << line
        elsif (included_code = CodeInclusion::Code.for(line)) && !in_verbatim
          # Reduce to a previously solved problem.
          # We transform
          # %= <<(/path/to/file.rb)
          # to
          # %= lang:rb
          # \begin{code}
          # <content of file or section.rb>
          # \end{code}
          # and then prepend the code to the current `lines` array.
          lines.unshift(*included_code.to_s)
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
                  text << line if line.math_environment? || (latex && !language)
                  break
                end
              end
              label = line if math && line =~ /^\s*\\label{.*?}\s*$/
              text << line
            end
            raise "Missing \\end{#{line.literal_type}}" if count != 0
            content = text.join("\n")
            if math
              key = digest(content)
              literal_cache[key] = content
            elsif language.nil?
              key = digest(content)
              literal_cache[key] = content
              tag = 'literal'
            else
              format = latex ? 'latex' : 'html'
              id = "#{content}--#{language}--#{format}--#{in_codelisting}--#{highlight_options}"
              key = digest(id, salt: code_salt)
              code_cache[key] = [content, language, in_codelisting, highlight_options]
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

    # Returns a permanent salt for the syntax highlighting cache.
    def code_salt
      'fbbc13ed4a51e27608037365e1d27a5f992b6339'
    end

    # Caches both display and inline math.
    def cache_display_inline_math(output)
      output.tap do
        cache_display_math(output)
        cache_inline_math(output)
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
    # We use this only for unnumbered, display equations, which requires using
    # the `equation*` environment in place of `equation`.
    def equation_element(content)
      key = digest(content)
      literal_cache[key] = content
      "\\begin{xmlelement*}{equation}
        \\begin{equation*}
        #{key}
        \\end{equation*}
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
      part     = language_labels["part"]
      chapter  = language_labels["chapter"]["word"]
      section  = language_labels["section"]
      appendix = language_labels["appendix"]
      table    = language_labels["table"]
      box      = language_labels["aside"]
      figure   = language_labels["figure"]
      fig      = language_labels["fig"]
      listing  = language_labels["listing"]
      equation = language_labels["equation"]
      eq       = language_labels["eq"]
      linked_item = "(#{part}|#{chapter}|#{section}|#{appendix}|#{table}|#{box}|#{figure}" +
                    "|#{fig}\.|#{listing}|#{equation}|#{eq}\.)"
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
      string.gsub!(non_ascii_unicode) do
        key = digest($1)
        unicode_cache[key] = $1
        key
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

class String
  include Polytexnic::Literal

  # Returns true if self matches \begin{...} where ... is a literal environment.
  # Note: Support for the 'metacode' environment exists solely to allow
  # meta-discussion of the 'code' environment.
  def begin_literal?(literal_type = nil)
    return false unless include?('\begin')
    literal_type ||= "(?:verbatim|Verbatim|code|metacode|" +
                     "#{math_environment_regex})"
    match(/^\s*\\begin{#{literal_type}}\s*$/)
  end

  # Returns true if self matches \end{...} where ... is a literal environment.
  def end_literal?(literal_type)
    return false unless include?('\end')
    match(/^\s*\\end{#{Regexp.escape(literal_type)}}\s*$/)
  end

  # Returns the type of literal environment.
  # '\begin{verbatim}' => 'verbatim'
  # '\begin{equation}' => 'equation'
  # '\[' => 'display'
  def literal_type
    scan(/\\begin{(.*?)}/).flatten.first || 'display'
  end

  # Returns true if self begins a math environment.
  def begin_math?
    return false unless include?('\begin')
    literal_type = "(?:#{math_environment_regex})"
    match(/^\s*\\begin{#{literal_type}}\s*$/)
  end

  # Returns true if self matches a valid math environment.
  def math_environment?
    match(/(?:#{math_environment_regex})/)
  end

  private

    # Returns a regex matching valid math environments.
    def math_environment_regex
      Polytexnic::Literal.math_environments.map do |s|
        Regexp.escape(s)
      end.join('|')
    end
end

