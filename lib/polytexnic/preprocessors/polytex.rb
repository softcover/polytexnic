# encoding=utf-8

require 'kramdown'
require 'securerandom'

$cache = {}
$label_salt = SecureRandom.hex

module Kramdown
  module Converter
    class Latex < Base

      # Converts `inline codespan`.
      # This overrides kramdown's default to use `\kode` instead of `\tt`.
      def convert_codespan(el, opts)
        "\\kode{#{latex_link_target(el)}#{escape(el.value)}}"
      end

      # Overrides default convert_a.
      # Unfortunately, kramdown is too aggressive in escaping characters
      # in hrefs, converting
      #     [foo bar](http://example.com/foo%20bar)
      # into
      #     \href{http://example.com/foo\%20bar}{foo bar}
      # The '\%20' in the href then won't work properly.
      def convert_a(el, opts)
        url = el.attr['href']
        if url =~ /^#/
          "\\hyperlink{#{escape(url[1..-1])}}{#{inner(el, opts)}}"
        else
          "\\href{#{url}}{#{inner(el, opts)}}"
        end
      end

      # Uses figures for images only when label is present.
      # This allows users to put raw (centered) images in their documents.
      # The default behavior of kramdown is to wrap such images in a figure
      # environment, which causes LaTeX to (a) treat them as floats and (b)
      # include a caption. This may not be what the user wants, and it's also
      # nonstandard Markdown. On the other hand, it is really nice to be
      # able to include captions using the default image syntax, so as a
      # compromise we use Markdown behavior by default and kramdown behavior
      # if the alt text contains a '\label' element.
      def convert_standalone_image(el, opts, img)
        alt_text = el.children.first.attr['alt']
        if has_label?(alt_text)
          attrs = attribute_list(el)
          # Override the kramdown default by adding "here" placement.
          # Authors who want a different behavior can always use raw LaTeX.
          "\\begin{figure}[H]#{attrs}\n\\begin{center}\n#{img}\n\\end{center}\n\\caption{#{escape(el.children.first.attr['alt'])}}\n#{latex_link_target(el, true)}\n\\end{figure}#{attrs}\n"
        else
          img.gsub('\includegraphics', '\image') + "\n"
        end
      end

      # Detects if text has a label.
      def has_label?(text)
        text.include?($label_salt)
      end
    end
  end
end

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
        math_cache = {}
        cleaned_markdown = cache_code_environments(@source)
        expand_input!(cleaned_markdown,
                      Proc.new { |source| cache_code_environments(source) })
        puts cleaned_markdown if debug?
        cleaned_markdown.tap do |markdown|
          convert_code_inclusion(markdown)
          cache_latex_literal(markdown)
          cache_raw_latex(markdown)
          cache_image_locations(markdown)
          puts markdown if debug?
          cache_math(markdown, math_cache)
        end
        puts cleaned_markdown if debug?
        # Override the header ordering, which starts with 'section' by default.
        lh = 'chapter,section,subsection,subsubsection,paragraph,subparagraph'
        kramdown = Kramdown::Document.new(cleaned_markdown, latex_headers: lh)
        puts kramdown.inspect if debug?
        puts kramdown.to_html if debug?
        puts kramdown.to_latex if debug?
        @source = kramdown.to_latex.tap do |polytex|
                    remove_kramdown_comments(polytex)
                    convert_includegraphics(polytex)
                    restore_math(polytex, math_cache)
                    restore_hashed_content(polytex)
                  end
      end

      # Adds support for <<(path/to/code) inclusion.
      def convert_code_inclusion(text)
        text.gsub!(/^\s*(<<\(.*?\))/) do
          key = digest($1)
          $cache[key] = "%= #{$1}"  # reduce to a previously solved case
          key
        end
      end

      # Caches literal LaTeX environments.
      def cache_latex_literal(markdown)
        # Add tabular and tabularx support.
        literal_types = Polytexnic::Literal.literal_types +
                        %w[tabular tabularx longtable]
        literal_types.each do |literal|
          regex = /(\\begin\{#{Regexp.escape(literal)}\}
                  .*?
                  \\end\{#{Regexp.escape(literal)}\})
                  /xm
          markdown.gsub!(regex) do
            content = $1
            key = digest(content)
            $cache[key] = content
            key
          end
        end
      end

      # Caches raw LaTeX commands to be passed through the pipeline.
      def cache_raw_latex(markdown)
        command_regex = /(
                          ^[ \t]*\\\w+.*\}[ \t]*$ # Command on line with arg
                          |
                          ~\\ref\{.*?\}     # reference with a tie
                          |
                          ~\\eqref\{.*?\}   # eq reference with a tie
                          |
                          \\[^\s]+\{.*?\}   # command with one arg
                          |
                          \\\w+             # normal command
                          |
                          \\-               # hyphenation
                          |
                          \\[ %&$\#@]       # space or special character
                          |
                          \\\\              # double backslashes
                          )
                        /x
        markdown.gsub!(command_regex) do
          content = $1
          puts content.inspect if debug?
          key = digest(content)
          # Used to speed up has_label? in convert_standalone_image.
          key += $label_salt if content.include?('\label')
          $cache[key] = content

          if content =~ /\{table\}|\\caption\{/
            # Pad tables & captions with newlines for kramdown compatibility.
            "\n#{key}\n"
          else
            key
          end
        end
      end

      # Caches the locations of images to be passed through the pipeline.
      # This works around a Kramdown bug, which fails to convert images
      # properly when their location includes a URL.
      def cache_image_locations(text)
        # Matches '![Image caption](/path/to/image)'
        text.gsub!(/^\s*(!\[.*?\])\((.*?)\)/) do
          key = digest($2)
          $cache[key] = $2
          "\n#{$1}(#{key})"
        end
      end

      # Restores raw code from the cache.
      def restore_hashed_content(text)
        $cache.each do |key, value|
          # Because of the way backslashes get interpolated, we need to add
          # some extra ones to cover all the cases of hashed LaTeX.
          text.gsub!(key, value.gsub(/\\/, '\\\\\\'))
        end
      end

      # Caches Markdown code environments.
      # Included are indented environments, Leanpub-style indented environments,
      # and GitHub-style code fencing.
      def cache_code_environments(source)
        output = []
        lines = source.split("\n")
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
          elsif line =~ /^```([\w+]*)(,\s*options:.*)?$/  # highlighted fences
            count = 1
            language = $1.empty? ? 'text' : $1
            options  = $2
            code = []
            while (line = lines.shift) do
              count += 1 if line =~ /^```.+$/
              count -= 1 if line.match(/^```\s*$/)
              break if count.zero?
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

      # Removes comments produced by kramdown.
      # These have the special form of always being at the beginning of the
      # line.
      def remove_kramdown_comments(text)
        text.gsub!(/^% (.*)$/, '')
      end

      # Converts \includegraphics to \image inside figures.
      # The reason is that raw \includegraphics is almost always too wide
      # in the PDF. Instead, we use the custom-defined \image command, which
      # is specifically designed to fix this issue.
      def convert_includegraphics(text)
        in_figure = false
        newtext = text.split("\n").map do |line|
          line.gsub!('\includegraphics', '\image') if in_figure
          if line =~ /^\s*\\begin\{figure\}/
            in_figure = true
          elsif line =~ /^\s*\\end\{figure\}/
            in_figure = false
          end
          line
        end.join("\n")
        text.replace(newtext)
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
        text.gsub!(/(?:\{\$\$\}\n(.*?)\n\{\/\$\$\}|\\\[(.*?)\\\])/m) do
          key = digest($1 || $2)
          cache[[:block, key]] = $1 || $2
          key
        end
        text.gsub!(/(?:\{\$\$\}(.*?)\{\/\$\$\}|\\\((.*?)\\\))/m) do
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
            open  = '\['
            close = '\]'
          end
          text.gsub!(key, open + value + close)
        end
      end
    end
  end
end
