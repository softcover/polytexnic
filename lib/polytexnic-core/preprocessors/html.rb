# encoding=utf-8
module Polytexnic
  module Preprocessor
    module Html

      # Converts HTML to XML.
      def to_xml
        polytex = process_for_tralics(@polytex)
        doc = Nokogiri::XML(tralics_xml(polytex))
        add_document_tag(doc)
        @xml = doc.to_xml
      end

      private

        # Processes the input PolyTeX for Tralics.
        def process_for_tralics(polytex)
          clean_document(polytex).tap do |output|
            hyperrefs(output)
            title_fields(output)
            maketitle(output)
            label_names(output)

            # Mark chapters with a 'chapter' type.
            output.gsub! /\\chapter\{(.*?)\}/ do |s|
              "#{s}\n\\AddAttToCurrent{type}{chapter}"
            end

            # Mark code listings with a 'codelisting' type.
            output.gsub! /\\begin\{codelisting\}/ do |s|
              "#{s}\n\\AddAttToCurrent{type}{codelisting}"
            end

            # Handles quote and verse environments, which Tralics does wrong.
            # Tralics converts
            # \begin{quote}
            #   foo
            #
            #   bar
            # \end{quote}
            # into
            # <p rend='quoted'>foo</p>
            # <p rend='quoted'>bar</p>
            # But we want the HTML to be
            # <blockquote>
            #   <p>foo</p>
            #   <p>bar</p>
            # </blockquote>
            # which can't easily be inferred from the Tralics output. (It gets
            # worse if you want to support nested blockquotes, which we do.)
            output.gsub!(/\\begin{quote}/, "\\xmlemptyelt{start-#{quote_digest}}")
            output.gsub!(/\\end{quote}/, "\\xmlemptyelt{end-#{quote_digest}}")
            output.gsub!(/\\begin{verse}/, "\\xmlemptyelt{start-#{verse_digest}}")
            output.gsub!(/\\end{verse}/, "\\xmlemptyelt{end-#{verse_digest}}")
          end
        end

        # Returns a clean document with cached literal environments.
        # This is a key step: we cache literal environments that should be
        # passed through the pipeline with no changes (verbatim, code, etc.).
        # The result is a document that can safely be transformed using
        # global substitutions.
        def clean_document(polytex)
          cache_unicode(make_caches(add_commands(polytex)))
        end

        # Handles title fields.
        def title_fields(string)
          %w{title subtitle author date}.each do |field|
            string.gsub! /\\#{field}\{(.*?)\}/ do |s|
              Polytexnic.instance_variable_set "@#{field}", $1
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
        # '\label{cha:foobar}'. But Tralics exposes a wide variety of
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

        # Adds some default commands.
        # The new_commands are currently in utils, but probably should
        # eventually be refactored into a file.
        def add_commands(polytex)
          new_commands + polytex
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

        # Returns the executable for the Tralics LaTeX-to-XML converter.
        def tralics
          `which tralics`.strip.tap do |tralics|
            if tralics.empty?
              $stderr.puts "Please install Tralics"
              $stderr.puts "See http://polytexnic.com/install"
              exit 1
            end
          end
        end

    end
  end
end
