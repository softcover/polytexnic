require "polytexnic-core/version"
require 'tempfile'
require 'nokogiri'
require 'digest/sha1'

module Polytexnic
  module Core

    $verbatim_cache = {}

    def self.polytex_to_html_fragment(polytex)
      tralics = `which tralics`.strip
      file = Tempfile.new(['polytex', '.tex'])
      file.write(preprocess(polytex))
      file.close
      system("#{tralics} -nomathml #{file.path} > /dev/null")
      dirname = File.dirname(file.path)
      xml_filename = File.basename(file.path, '.tex') + '.xml'
      raw_xml = File.read(File.join(dirname, xml_filename))
      xml = Nokogiri::XML(raw_xml).at_css('p').to_xml
      html = xml_to_html(postprocess(xml))
      Nokogiri::HTML(html).to_html
    ensure
       file.unlink
    end

    def self.digest(string)
      Digest::SHA1.hexdigest(string)
    end

    def self.preprocess(polytex)
      output = []
      lines = polytex.split("\n")
      while (line = lines.shift)
        if line =~ /^\s*\\begin{verbatim}\s*$/
          output << xmlelement(:verbatim) do
            verbatim_count = 1
            verbatim_text = []
            while (line = lines.shift)
              if line =~ /^\s*\\begin{verbatim}\s*$/
                verbatim_count += 1
              elsif line =~ /^\s*\\end{verbatim}\s*$/
                verbatim_count -= 1
                break if verbatim_count == 0
              end
              verbatim_text << line if verbatim_count > 0
            end
            raise 'Missing \end{verbatim}' if verbatim_count != 0
            content = verbatim_text.join("\n")
            key = self.digest(content)
            $verbatim_cache[key] = content
            key
          end
        else
          output << line
        end
      end
      # puts output.join("\n")
      output.join("\n")
    end

    def self.xmlelement(name)
      output = "\\begin{xmlelement}{#{name}}"
      output << yield if block_given?
      output << "\\end{xmlelement}"
    end

    def self.postprocess(xml)
      $verbatim_cache.each do |key, value|
        xml.gsub!(key, value)
      end

      xml
    end

    def self.xml_to_html(xml)
      doc = Nokogiri::XML(xml)
      doc.xpath('//hi[@rend="it"]').each do |node|
        node.name = 'em'
        node.xpath('//@rend').remove
      end
      doc.xpath('//verbatim').each do |node|
        node.name = 'pre'
        node['class'] = 'verbatim'
      end

      # handle footnotes
      footnotes_node = nil
      doc.xpath('//note[@place="foot"]').each_with_index do |node, i|
        n = i + 1
        note = Nokogiri::XML::Node.new('div', doc)
        note['id'] = "footnote-#{n}"
        note['class'] = 'footnote'
        note.content = node.content

        unless footnotes_node
          footnotes_node = Nokogiri::XML::Node.new('div', doc)
          footnotes_node['id'] = 'footnotes'
          doc.root.add_child footnotes_node
        end

        footnotes_node.add_child note

        node.name = 'sup'
        %w{id-text id place}.each { |a| node.remove_attribute a }
        node['class'] = 'footnote'
        link = Nokogiri::XML::Node.new('a', doc)
        link['href'] = "#footnote-#{n}"
        link.content = n.to_s
        node.inner_html = link
      end

      # LaTeX logo
      doc.xpath('//LaTeX').each do |node|
        node.name = 'span'
        node['class'] = 'LaTeX'
      end

      doc.to_html
    end
  end
end
