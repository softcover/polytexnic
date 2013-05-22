# encoding=utf-8
require 'cgi'
require 'polytexnic-core/postprocessors/html'

module Polytexnic
  module Postprocessor
    include Html

    def postprocess(format)
      if format == :html
        @html = xml_to_html(@xml)
      end
    end
  end
end