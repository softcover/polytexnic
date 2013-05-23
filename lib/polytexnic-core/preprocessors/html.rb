# encoding=utf-8
module Polytexnic
  module Preprocessor
    module Html

      # Converts HTML to XML.
      def to_xml
        tralics = `which tralics`.strip
        file = Tempfile.new(['polytex', '.tex'])
        file.write process_for_tralics(@polytex)
        file.close
        Dir.mkdir 'log' unless File.directory?('log')
        system("#{tralics} -nomathml #{file.path} > log/tralics.log")
        dirname = File.dirname(file.path)
        xml_filename = File.basename(file.path, '.tex') + '.xml'
        raw_xml = clean_xml File.read(File.join(dirname, xml_filename))
        doc = Nokogiri::XML(raw_xml)
        add_document_tag(doc)
        @xml = doc.to_xml
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

      # Processes the input PolyTeX for Tralics.
      def process_for_tralics(polytex)
        defs = '\def\hyperref[#1]#2{\xmlelt{a}{\XMLaddatt{target}{#1}#2}}'
        polytex = "#{defs}\n#{polytex}"

        output = hyperref(cache_unicode(make_caches(polytex)))

        # handle title fields
        %w{title subtitle author date}.each do |field|
          output.gsub! /\\#{field}\{(.*?)\}/ do |s|
            Polytexnic.instance_variable_set "@#{field}", $1
            ''
          end
        end

        output.gsub! /\\maketitle/ do |s|
          xmlelement('maketitle')
        end

        # preserve label names
        output.gsub! /\\label\{(.*?)\}/ do |s|
          "#{s}\n\\AddAttToCurrent{data-label}{#{$1}}"
        end

        output.gsub! /\\chapter\{(.*?)\}/ do |s|
          "#{s}\n\\AddAttToCurrent{type}{chapter}"
        end

        output
      end

      def clean_xml(raw_xml)
        nokogiri_ellipsis_workaround(raw_xml)
      end

      # Fixes a Nokogiri bug.
      # As of this writing, the latest version of Nokogiri (1.5.6) doesn't
      # handle the horizontal ellipsis character '&#133;' correctly in Ruby 2.0.
      # The kludgy solution is to replace it with '…' in the raw XML,
      # which does work.
      def nokogiri_ellipsis_workaround(raw_xml)
        raw_xml.gsub('&#133;', '…')
      end
    end
  end
end
