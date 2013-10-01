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
      # attempt to bolt on the functionality needed to write longer documents
      # (but why not just use LaTeX?). At this point, I fear that "Markdown"
      # has become little more than a marketing term.</rant>
      def to_polytex
        require 'Kramdown'
        cleaned_markdown = cache_code_environments
        math_cache = cache_math(cleaned_markdown)
        # Override the header ordering, which starts with 'section' by default.
        lh = 'chapter,section,subsection,subsubsection,paragraph,subparagraph'
        kramdown = Kramdown::Document.new(cleaned_markdown, latex_headers: lh)
        @source = restore_math(kramdown.to_latex, math_cache)
      end

      def cache_code_environments
        output = []
        lines = @source.split("\n")
        while (line = lines.shift)
          if line =~ /\{lang="(.*?)"\}/
            language = $1
            code = []
            indentation = ' ' * 4

            while (line = lines.shift) && line.match(/^#{indentation}(.*)$/) do
              code << $1
            end
            code = code.join("\n")
            key = digest(code)
            code_cache[key] = [code, language]
            output << key
            output << line
          else
            output << line
          end
        end
        output.join("\n")
      end

      def cache_math(text)
        cache = {}
        text.gsub!(/\{\$\$\}(.*?)\{\/\$\$\}/) do
          key = digest($1)
          cache[[:inline, key]] = $1
          key
        end
        cache
      end

      def restore_math(text, cache)
        cache.each do |(kind, key), value|
          text.gsub!(key, '\(' + value + '\)')
        end
        text
      end
    end
  end
end