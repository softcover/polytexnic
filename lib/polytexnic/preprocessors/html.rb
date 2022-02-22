# encoding=utf-8
module Polytexnic
  module Preprocessor
    module Html

      # Converts HTML to XML.
      # The heart of the process is using Tralics to convert the input PolyTeX
      # to XML. The raw PolyTeX needs to be processed first to make everything
      # go smoothly, but after that the steps to producing the corresponding
      # XML is straightforward.
      def to_xml
        polytex = process_for_tralics(@polytex)
        puts "after processing for Tralics:\n#{polytex}" if debug?
        doc = Nokogiri::XML(tralics_xml(polytex))
        add_document_tag(doc)
        @xml = doc.to_xml
      end

      private

        # Processes the input PolyTeX for Tralics.
        # The key steps are creating a clean document safe for making global
        # substitutions (gsubs), and then making a bunch of gsubs.
        def process_for_tralics(polytex)
          clean_document(polytex).tap do |output|
            process_spaces(output)
            remove_commands(output)
            hyperrefs(output)
            title_fields(output)
            maketitle(output)
            convert_longtable(output)
            label_names(output)
            image_names(output)
            restore_eq_labels(output)
            convert_float_centering(output)
            mark_environments(output)
            make_tabular_alignment_cache(output)
            cache_unicode(output)
          end
        end

        # Returns a clean document with cached literal environments.
        # This is a key step: we cache literal environments that should be
        # passed through the pipeline with no changes (verbatim, code, etc.).
        # The result is a document that can safely be transformed using
        # global substitutions.
        def clean_document(polytex)
          doc = cache_literal(add_commands(polytex))
          expand_input!(doc, Proc.new { |source| cache_literal(source) }, 'tex')
          inline_verbatim(doc)
          cache_urls(doc)
          remove_comments(doc)
          double_backslashes(cache_display_inline_math(doc))
        end

        # Prepares spaces to be passed through the pipeline.
        # Handles thin spaces ('\,') and normal spaces ('\ '), as well as
        # end-of-sentence spaces.
        def process_spaces(doc)
          doc.gsub!(/\\,/, xmlelement('thinspace'))
          # Match an end of sentence character, while also recognizing
          # things like (Or otherwise.) and ``Yes, indeed!'' as being the
          # ends of sentences.
          end_of_sentence = '[.?!](?:\)|\'+)?'
          # Handle a forced normal space '\ '.
          doc.gsub!(/(#{end_of_sentence})\\ /) do
            $1 + xmlelement('normalspace')
          end
          not_a_capital = '[^A-Z]'
          # Case of "foo. A"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})[ \t]+([^\s])/) do
            $1 + $2 + xmlelement('intersentencespace') + ' ' + $3
          end
          # Case of "foo.\nA" or "foo.\n A"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})[ \t]*\n[ \t]*([^\s])/) do
            $1 + $2 + xmlelement('intersentencespace') + ' ' + $3
          end
          # Case of "foo.} A" or "foo.}} A"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})(\}+)[ \t]+([^\s])/) do
            $1 + $2 + $3 + xmlelement('intersentencespace') + ' ' + $4
          end
          # Case of "foo.} A" or "foo.}'' A"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})(\}+)(''|')[ \t\n]+([^\s])/) do
            $1 + $2 + $3 + $4 + xmlelement('intersentencespace') + ' ' + $5
          end
          # Case of "foo.] A"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})(\]+)[ \t]+([^\s])/) do
            $1 + $2 + $3 + xmlelement('intersentencespace') + ' ' + $4
          end
          # Case of "foo.'') A"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})('+)(\))[ \t]+([^\s])/) do
            $1 + $2 + $3 + $4 + xmlelement('intersentencespace') + ' ' + $5
          end
          # Case of "foo.}\nA" or "foo.}}\nA"
          # Matching '.}\n\label' messes up aside boxes, so as a compromise
          # we detect '.}\n\w', which matches virtually all use cases.
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})(\}+)\n[ \t]*(\w+)/) do
            $1 + $2 + $3 + xmlelement('intersentencespace') + ' ' + $4
          end
          # Case of "foo.')\nA" or "foo.'')\nA"
          doc.gsub!(/(#{not_a_capital})(#{end_of_sentence})('+)(\))\n([^\s])/) do
            $1 + $2 + $3 + $4 + xmlelement('intersentencespace') + ' ' + $5
          end
          # Handle the manual override to force an intersentence space, '\@',
          # as in 'Superman II\@. A new sentence'.
          doc.gsub!(/\\@\. /, '.' + xmlelement('intersentencespace') + ' ')
        end

        # Removes commands that might screw up Tralics.
        def remove_commands(doc)
          # Determine if we're using footnote symbols.
          symbols_cmd = '\renewcommand{\thefootnote}{\fnsymbol{footnote}}'
          @footnote_symbols = !!doc.match(/^\s*#{Regexp.escape(symbols_cmd)}/)

          doc.gsub!(/^\s*\\renewcommand.*$/, '')
        end

        # Returns true if we should use footnote symbols in place of numbers.
        def footnote_symbols?
          @footnote_symbols
        end

        # Handles \verb environments.
        # LaTeX supports an inline verbatim environment using
        #   \verb+<stuff>+
        # The + is arbitrary; any non-letter character is fine as long as it
        # doesn't appear in <stuff>, so this code has exactly the same effect:
        #   \verb!<stuff>!
        #   \verb@<stuff>@
        #   \verb8<stuff>8
        # My preference is to use + or - if available.
        def inline_verbatim(doc)
          doc.gsub!(/\\verb([^A-Za-z])(.*?)\1/) do
            key = digest($2)
            literal_cache[key] = $2
            xmlelement('inlineverbatim') { key }
          end
        end

        # Removes commented-out lines.
        # Contents of the special sequence `%=` are converted to literal HTML.
        def remove_comments(output)
          output.gsub!(/([^\\])(%[^=].*$)/, '\1')
          output.gsub!(/[^\\]%=(.*)$/) do
            key = digest($1)
            literal_html_cache[key] = $1
            xmlelement('literalhtml') { key }
          end
        end

        # Converts LaTeX double backslashes to HTML breaks.
        def double_backslashes(string)
          lines = []
          in_table = false
          string.split("\n").each do |line|
            in_table ||= (line =~ /^\s*\\begin{(?:tabularx?|longtable)}/)
            line.gsub!('\\\\', xmlelement('backslashbreak')) unless in_table
            lines << line
            in_table = (in_table && line !~ /^\s*\\end{tabularx?}/)
          end
          lines.join("\n")
        end

        # Adds some default commands.
        def add_commands(polytex)
          line(custom_commands) + tralics_commands + polytex
        end

        # Pads a string with newlines.
        def line(string)
          "\n#{string}\n"
        end

        # Handles title fields.
        def title_fields(string)
          %w{title subtitle author date}.each do |field|
            string.gsub! /\\#{field}\{(.*)\}/ do |s|
              maketitle_elements[field] = $1
              ''
            end
          end
        end

        # Replaces maketitle with an XML element.
        def maketitle(string)
          string.gsub! /\\maketitle/ do |s|
            xmlelement('maketitle')
          end
        end

        # Preserves label names.
        # Tralics doesn't keep the names of labels, e.g., 'cha:foobar' in
        # '\label{cha:foobar}'. But Tralics supplies a wide variety of
        # pseudo-LaTeX commands to add arbitrary XML elements to the final
        # document. In this case, the \xbox command does the trick. See
        # http://www-sop.inria.fr/marelle/tralics/doc-x.html
        # for more information.
        def label_names(string)
          string.gsub! /\\label\{(.*?)\}/ do |s|
            label = $1.gsub(':', '-').gsub('_', underscore_digest)
            "#{s}\n\\xbox{data-label}{#{label}}"
          end
        end

        # Handles image names with underscores.
        # This is a terrible kludge, and it's annoying that it's
        # apparently necessary.
        def image_names(string)
          string.gsub! /\\image\{(.*?)\}/ do |s|
            escaped_filename = $1.gsub('_', underscore_digest)
            "\\image{#{escaped_filename}}"
          end
          string.gsub! /\\imagebox\{(.*?)\}/ do |s|
            escaped_filename = $1.gsub('_', underscore_digest)
            "\\imagebox{#{escaped_filename}}"
          end
        end

        # Restores the equation labels.
        def restore_eq_labels(output)
          math_label_cache.each do |key, label|
            output.gsub!(key, label)
          end
        end

        # Handles centering in floats (figures and tables).
        # The way we handle generic \begin{center}...\end{center} doesn't
        # work in floats for some reason. Luckily, the preferred method
        # is to use \centering anyway, so this kludge is actually better LaTeX.
        def convert_float_centering(output)
          @in_float = false
          centered = []
          quote_or_verse = []
          output.split("\n").each do |line|
            if line =~ /^\s*\\begin\{(figure|table)\}/
              @in_float = true
              @float_type = $1
              centered << line
            elsif @in_float && line =~ /^\s*\\begin\{center\}/
              centered << '\centering'
            elsif @in_float && line =~ /^\s*\\end\{center\}/
              centered << ''
            elsif @in_float && line =~/^\s*\\footnotesize/
              # Removes \footnotesize in floats.
              # This sizing is useful for tables
              # in some LaTeX PDF contexts, but not in HTML,
              # and it messes up the conversion.
              centered << ''
            elsif @in_float && line =~ /^\s*\\end\{#{@float_type}\}/
              @in_float = false
              centered << line
            elsif @in_float && line =~ /^\s*\\begin\{(?:verse|quote)\}/
              quote_or_verse << line
              @in_quote = true
              centered << ''
            elsif @in_float && line =~ /^\s*\\end\{(?:verse|quote)\}/
              quote_or_verse << line
              quote = quote_or_verse.join("\n")
              key = digest(latex)
              html = Polytexnic::Pipeline.new(quote,
                                              literal_cache: literal_cache).to_html
              figure_quote_cache[key] = html
              @in_quote = false
              quote_or_verse = []
              centered << key
            elsif @in_quote
              quote_or_verse << line
              centered << ''
            else
              centered << line
            end
          end
          output.replace(centered.join("\n"))
        end

        # Converts the alt table environments to simple tabular.
        # This is was originaly because kramdown outputs longtables by default,
        # but as a side-effect you can also use longtables in PolyTeX
        # input documents. The latest update includes support for the tabularx
        # environment
        def convert_longtable(output)
          output.gsub!(/\\begin\{longtable\}(\{.*?\})\n\s*((?:\\caption|\\label).*?)\\\\$/) do
            "\\begin{table}\n#{$2}\n\\begin{tabular}#{$1}"
          end
          output.gsub!(/\\begin\{longtable\}(\{.*?\})/) do
            "\\begin{table}\n\\begin{tabular}#{$1}"
          end
          output.gsub!(/((?:\\caption|\\label).*?$)\n\s*\\end\{longtable\}/) do
            "\\end{tabular}#{$1}\n\\end{table}"
          end
          output.gsub!('\end{longtable}', "\\end{tabular}\n\\end{table}")
          output.gsub!(/\\begin\{tabularx\}\{.*?\}\{(.*)\}/) do
            alignment = $1.gsub('X', 'l')   # X becomes left-justified in HTML
            "\\begin{tabular}{#{alignment}}"
          end
          output.gsub!('\end{tabularx}', '\end{tabular}')
        end

        # Marks environments with their types.
        # Tralics strips some information when processing LaTeX, such as
        # whether a particular div defines a chapter. We remedy this by
        # using the \AddAttToCurrent pseudo-LaTeX command to mark such
        # environments with their types.
        def mark_environments(string)

          # Marks chapters with a 'chapter' type.
          # Also handles \chapter*.
          string.gsub! /^\s*\\chapter\*?\{(.*)\}/ do |s|
            "#{s}\n\\AddAttToCurrent{type}{chapter}"
          end

          # Wrap codelistings in a 'codelisting' element.
          string.gsub! /\\begin{codelisting}/ do |s|
            "\\begin{xmlelement*}{codelisting}\n#{s}"
          end
          string.gsub! /\\end{codelisting}/ do |s|
            "#{s}\n\\end{xmlelement*}"
          end

          # Wrap asides in an 'aside' element.
          string.gsub! /\\begin{aside}/ do |s|
            "\\begin{xmlelement*}{aside}\n#{s}"
          end
          string.gsub! /\\end{aside}/ do |s|
            "#{s}\n\\end{xmlelement*}"
          end

          # Replace quotations and verse with corresponding XML elements.
          string.gsub! /\\begin{quote}/ do |s|
            quotation = '\AddAttToCurrent{class}{quotation}'
            "\\begin{xmlelement*}{blockquote}\n#{quotation}"
          end
          string.gsub! /\\end{quote}/ do |s|
            "\\end{xmlelement*}"
          end
          string.gsub! /\\begin{verse}/ do |s|
            "\\begin{xmlelement*}{blockquote}\n\\AddAttToCurrent{class}{verse}"
          end
          string.gsub! /\\end{verse}/ do |s|
            "\\end{xmlelement*}"
          end

          # Handle \begin{center}...\end{center}
          string.gsub! /\\begin{center}/, '\begin{xmlelement*}{center}'
          string.gsub! /\\end{center}/,   '\end{xmlelement*}'

          # Handle \centering
          string.gsub! /\\centering/, '\AddAttToCurrent{class}{center}'

          # # Handle \image
          # string.gsub! /\\image/, '\includegraphics'
        end

        # Collects alignment information for tabular environments.
        # We suck out all the stuff like 'l|l|lr' in
        # \begin{tabular}{l|l|lr}
        # The reason is that we need to work around a couple of bugs in Tralics.
        # I've tried in vain to figure out WTF is going on in the Tralics
        # source, but it's easy enough in Ruby so I'm throwing it in here.
        def make_tabular_alignment_cache(output)
          alignment_regex = /^\s*\\begin{tabular}{\s*((?:\|*[lcr]+\|*)+)\s*}/
          @tabular_alignment_cache = output.scan(alignment_regex).flatten
        end

        # Returns the XML produced by the Tralics program.
        # There is a lot of ugly file manipulation here, but it's fundamentally
        # straightforward. The heart of it is
        #
        #   system("#{tralics} -nomathml #{file.path} > log/tralics.log")
        #
        # which writes the converted PolyTeX file as XML, which then gets
        # read in and lightly processed.
        def tralics_xml(polytex)
          file = Tempfile.new(['polytex', '.tex'])
          puts polytex if debug?
          file.write(polytex)
          file.close
          Dir.mkdir 'log' unless File.directory?('log')
          system("#{tralics} -nomathml #{file.path} > log/tralics.log")
          dirname = File.dirname(file.path)
          xml_filename = File.basename(file.path, '.tex') + '.xml'
          raw_xml = File.read(File.join(dirname, xml_filename))
          xml = clean_xml(raw_xml)
          puts xml if debug?
          xml
        ensure
          xmlfile = file.path.sub('.tex', '.xml')
          logfile = file.path.sub('.tex', '.log')
          [xmlfile, logfile].each do |file|
            File.delete(file) if File.exist?(file)
          end
          file.delete
        end

        # Wraps the whole document in <document></document>.
        # Fragmentary documents come wrapped in 'unknown' tags.
        # Full documents are wrapped in 'std' tags.
        # Change either to 'document' for consistency.
        def add_document_tag(doc)
          %w[unknown std].each do |parent_tag|
            node = doc.at_css(parent_tag)
            node.name = 'document' unless node.nil?
          end
        end

        def clean_xml(raw_xml)
          nokogiri_ellipsis_workaround(raw_xml)
        end

        # Fixes a Nokogiri bug.
        # As of this writing, the latest version of Nokogiri (1.5.6) doesn't
        # handle the horizontal ellipsis character '&#133;' correctly in Ruby 2.
        # The kludgy solution is to replace it with '…' in the raw XML,
        # which does work.
        def nokogiri_ellipsis_workaround(raw_xml)
          raw_xml.gsub('&#133;', '…')
        end
    end
  end
end
