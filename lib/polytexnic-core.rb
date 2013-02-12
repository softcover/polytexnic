require "polytexnic-core/version"
require 'tempfile'
require 'open3'
require 'nokogiri'

module Polytexnic
  module Core
    def self.polytex_to_html_fragment(polytex)
      tralics = `which tralics`.strip
      file = Tempfile.new(['polytex', '.tex'])
      file.write(preprocess(polytex))
      file.close
      system("#{tralics} -nomathml #{file.path} > /dev/null")
      dirname = File.dirname(file.path)
      xml_filename = File.basename(file.path, '.tex') + '.xml'
      xml_to_html(File.read(File.join(dirname, xml_filename)))
    ensure
       file.unlink
    end

    def self.preprocess(polytex)
      polytex
    end

    def self.xml_to_html(xml)
      doc = Nokogiri::XML(xml)
      doc.xpath('//hi[@rend="it"]').each do |node|
        node.name = 'em'
        node.xpath('//@rend').remove
      end
      doc.to_html
    end
  end
end
