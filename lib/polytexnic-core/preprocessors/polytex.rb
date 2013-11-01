# encoding=utf-8
module Polytexnic
  module Preprocessor
    module Polytex

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
        cleaned_markdown = cache_code_environments
        cleaned_markdown.tap do |markdown|
          convert_code_inclusion(markdown)
        end
        math_cache = cache_math(cleaned_markdown)
        # Override the header ordering, which starts with 'section' by default.
        lh = 'chapter,section,subsection,subsubsection,paragraph,subparagraph'
        kramdown = Kramdown::Document.new(cleaned_markdown, latex_headers: lh)
        @source = restore_inclusion(restore_math(kramdown.to_latex, math_cache))
      end

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
          elsif line =~ /^```(\w+)\s*$/   # syntax-highlighted code fences
            language = $1
            code = []
            while (line = lines.shift) && !line.match(/^```\s*$/) do
              code << line
            end
            code = code.join("\n")
            key = digest(code)
            code_cache[key] = [code, language]
            output << key
          else
            output << line
          end
        end
        output.join("\n")
      end

      # Caches Leanpub-style math.
      # Leanpub uses the notation {$$}...{/$$} for both inline and block math,
      # with the only difference being the presences of newlines:
      #     {$$} x^2 {/$$}  % inline
      # and
      #     {$$}
      #     x^2             % block
      #     {/$$}
      # I personally hate this notation and convention, but anyone who really
      # cares should just use PolyTeX instead of Markdown.
      def cache_math(text)
        cache = {}
        text.gsub!(/\{\$\$\}\n(.*?)\n\{\/\$\$\}/) do
          key = digest($1)
          cache[[:block, key]] = $1
          key
        end
        text.gsub!(/\{\$\$\}(.*?)\{\/\$\$\}/) do
          key = digest($1)
          cache[[:inline, key]] = $1
          key
        end
        cache
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
        text
      end
    end

    # Adds support for <<(path/to/code) inclusion.
    def convert_code_inclusion(text)
      text.gsub!(/^\s*<<\((.*?)\)/) { "<!-- inclusion= <<#{$1}-->" }
    end
    def restore_inclusion(text)
      text.gsub(/% <!-- inclusion= (.*?)-->/) { "%= #{$1}" }
    end
  end
end