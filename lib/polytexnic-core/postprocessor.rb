# encoding=utf-8
require 'cgi'
require 'polytexnic-core/postprocessors/html'

module Polytexnic
  module Postprocessor
    include Html

    def postprocess(format)
      if format == :html
        xml_to_html
      end
    end
  end
end