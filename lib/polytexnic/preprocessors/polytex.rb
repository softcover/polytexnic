# encoding=utf-8
module Polytexnic
  module Preprocessor
    module Polytex
      include Polytexnic::Literal

      # Converts Markdown to PolyTeX.
      # We adopt a unified approach: rather than convert "Markdown" (I use
      # the term loosely*) directly to HTML, we convert it to PolyTeX and
      # then run everything through the PolyTeX pipeline. Happily, kramdown
      # comes equipped with a `to_latex` method that does most of the heavy
      # lifting. The ouput isn't as clean as that produced by Pandoc (our
      # previous choice), but it comes with significant advantages: (1) It's
      # written in Ruby, available as a gem, so its use eliminates an external
      # dependency. (2) It's the foundation for the "Markdown" interpreter
      # used by Leanpub, so by using it ourselves we ensure greater
      # compatibility with Leanpub books.
      #
      # * <rant>The number of mutually incompatible markup languages going
      # by the name "Markdown" is truly mind-boggling. Most of them add things
      # to John Gruber's original Markdown language in an ever-expanding
      # attempt to bolt on the functionality needed to write longer documents.
      # At this point, I fear that "Markdown" has become little more than a
      # marketing term.</rant>
      def to_polytex
        require 'Kramdown'
        cache = {}
        math_cache = {}
        cleaned_markdown = cache_code_environments
        puts cleaned_markdown if debug?
        cleaned_markdown.tap do |markdown|
          convert_code_inclusion(markdown, cache)
          cache_latex_literal(markdown, cache)
          cache_raw_latex(markdown, cache)
          puts markdown if debug?
          cache_math(markdown, math_cache)
        end
        puts cleaned_markdown if debug?
        # Override the header ordering, which starts with 'section' by default.
        lh = 'chapter,section,subsection,subsubsection,paragraph,subparagraph'
        kramdown = Kramdown::Document.new(cleaned_markdown, latex_headers: lh)
        @source = kramdown.to_latex.tap do |polytex|
                    remove_comments(polytex)
                    convert_includegraphics(polytex)
                    convert_tt(polytex)
                    restore_math(polytex, math_cache)
                    restore_hashed_content(polytex, cache)
                  end
      end

      # Adds support for <<(path/to/code) inclusion.
      def convert_code_inclusion(text, cache)
        text.gsub!(/^\s*(<<\(.*?\))/) do
          key = digest($1)
          cache[key] = "%= #{$1}"  # reduce to a previously solved case
          key
        end
      end

      # Caches literal LaTeX environments.
      def cache_latex_literal(markdown, cache)
        Polytexnic::Literal.literal_types.each do |literal|
          regex = /(\\begin\{#{Regexp.escape(literal)}\}
                  .*?
                  \\end\{#{Regexp.escape(literal)}\})
                  /xm
          markdown.gsub!(regex) do
            key = digest($1)
            cache[key] = $1
            key
          end
        end
      end

      # Caches raw LaTeX commands to be passed through the pipeline.
      def cache_raw_latex(markdown, cache)
        command_regex = /(
                          ^\s*\\\w+.*\}[ \t]*$ # Command on line with arg
                          |
                          ~\\ref\{.*?\}     # reference with a tie
                          |
                          ~\\eqref\{.*?\}   # eq reference with a tie
                          |
                          \\[^\s]+\{.*?\}   # command with one arg
                          |
                          \\\w+             # normal command
                          |
                          \\[ %&$#@]        # space or special character
                          )
                        /x
        markdown.gsub!(command_regex) do
          content = $1
          key = digest(content)
          cache[key] = content

          if content =~ /\{table\}|\\caption\{/
            # Pad tables & captions with newlines for kramdown compatibility.
            "\n#{key}\n"
          else
            key
          end
        end
      end

      # Restores raw code from the cache
      def restore_hashed_content(text, cache)
        cache.each do |key, value|
          # Because of the way backslashes get interpolated, we need to add
          # some extra ones to cover all the cases of hashed LaTeX.
          text.gsub!(key, value.gsub(/\\/, '\\\\\\'))
        end
      end

      # Caches Markdown code environments.
      # Included are indented environments, Leanpub-style indented environments,
      # and GitHub-style code fencing.
      def cache_code_environments
        output = []
        lines = @source.split("\n")
        indentation = ' ' * 4
        while (line = lines.shift)
          if line =~ /\{lang="(.*?)"\}/
            language = $1
            code = []
            while (line = lines.shift) && line.match(/^#{indentation}(.*)$/) do
              code << $1
            end
            code = code.join("\n")
            key = digest(code)
            code_cache[key] = [code, language]
            output << key
            output << line
          elsif line =~ /^```\s*$/        # basic code fences
            while (line = lines.shift) && !line.match(/^```\s*$/)
              output << indentation + line
            end
            output << "\n"
          elsif line =~ /^```(\w+)(,\s*options:.*)?$/  # highlighted fences
            language = $1
            options  = $2
            code = []
            while (line = lines.shift) && !line.match(/^```\s*$/) do
              code << line
            end
            code = code.join("\n")
            data = [code, language, false, options]
            key = digest(data.join("--"))
            code_cache[key] = data
            output << key
          else
            output << line
          end
        end
        output.join("\n")
      end

      # Converts \includegraphics to \image.
      # The reason is that raw \includegraphics is almost always too wide
      # in the PDF. Instead, we use the custom-defined \image command, which
      # is specifically designed to fix this issue.
      def convert_includegraphics(text)
        text.gsub!('\includegraphics', '\image')
      end

      # Converts {tt ...} to \kode{...}
      # This effectively converts `inline code`, which kramdown sets as
      # {\tt inline code}, to PolyTeX's native \kode command, which in
      # turns allows inline code to be separately styled.
      def convert_tt(text)
        text.gsub!(/\{\\tt (.*?)\}/, '\kode{\1}')
      end

      # Caches math.
      # Leanpub uses the notation {$$}...{/$$} for both inline and block math,
      # with the only difference being the presences of newlines:
      #     {$$} x^2 {/$$}  % inline
      # and
      #     {$$}
      #     x^2             % block
      #     {/$$}
      # I personally hate this notation and convention, so we also support
      # LaTeX-style \( x \) and \[ x^2 - 2 = 0 \] notation.
      def cache_math(text, cache)
        text.gsub!(/(?:\{\$\$\}\n(.*?)\n\{\/\$\$\}|\\\[(.*?)\\\])/) do
          key = digest($1 || $2)
          cache[[:block, key]] = $1 || $2
          key
        end
        text.gsub!(/(?:\{\$\$\}(.*?)\{\/\$\$\}|\\\((.*?)\\\))/) do
          key = digest($1 || $2)
          cache[[:inline, key]] = $1 || $2
          key
        end
      end

      # Restores the Markdown math.
      # This is easy because we're running everything through our LaTeX
      # pipeline.
      def restore_math(text, cache)
        cache.each do |(kind, key), value|
          case kind
          when :inline
            open  = '\('
            close =  '\)'
          when :block
            open  = '\[' + "\n"
            close = "\n" + '\]'
          end
          text.gsub!(key, open + value + close)
        end
      end
    end
  end
end