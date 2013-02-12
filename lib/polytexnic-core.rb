require "polytexnic-core/version"

module Polytexnic
  module Core
    def self.polytex_to_html_fragment(polytex)
      xml_to_html(polytex)
    end

    def self.xml_to_html(xml)
      xml
    end
  end
end
