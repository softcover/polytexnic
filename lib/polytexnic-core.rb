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
      xml = File.read(File.join(dirname, xml_filename))
      html = xml_to_html(postprocess(xml))
      Nokogiri::HTML(html).at_css('p').to_html
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
          output << '\begin{xmlelement}{verbatim}'
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
          output << key
          output << '\end{xmlelement}'
        else
          output << line
        end
      end
      # puts output.join("\n")
      output.join("\n")
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
        node.name = 'span'
        node['class'] = 'verbatim'
      end
      doc.to_html
    end
  end
end
