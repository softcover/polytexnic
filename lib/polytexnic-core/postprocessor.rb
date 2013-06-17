# encoding=utf-8
require 'cgi'
require 'polytexnic-core/postprocessors/html'
require 'polytexnic-core/postprocessors/latex'

module Polytexnic
  module Postprocessor
    include Html
    include Latex

    def postprocess(format)
      if format == :html
        @html = xml_to_html(@xml)
      elsif format == :latex
        hyperrefs(@polytex)
        raw_source = replace_hashes(@polytex)
        @latex = highlight_source_code(raw_source, 'latex')
      end
    end
  end
end