require "polytexnic-core/version"
require 'tempfile'
require 'open3'
require 'nokogiri'

module Polytexnic
  module Core
    def self.polytex_to_html_fragment(polytex)
      tralics = `which tralics`.strip
      file = Tempfile.new(['polytex', '.tex'])
      file.write(polytex)
      file.close
      system("#{tralics} -nomathml #{file.path} > /dev/null")
      dirname = File.dirname(file.path)
      xml_filename = File.basename(file.path, '.tex') + '.xml'
      xml_to_html(File.read(File.join(dirname, xml_filename)))
    ensure
       file.unlink
    end

    def self.xml_to_html(xml)
      xml
    end
  end
end
