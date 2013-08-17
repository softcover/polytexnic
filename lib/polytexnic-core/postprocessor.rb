# encoding=utf-8
require 'cgi'
require 'polytexnic-core/postprocessors/html'
require 'polytexnic-core/postprocessors/latex'
require 'polytexnic-core/postprocessors/polytex'

module Polytexnic
  module Postprocessor
    include Html
    include Latex
    include Polytex

    def postprocess(format)
      if format == :html
        @html = xml_to_html(@xml)
      elsif format == :latex
        hyperrefs(@polytex)
        raw_source = replace_hashes(@polytex)
        @latex = highlight_source_code(raw_source)
      elsif format == :polytex
        @source = sub_things
      end
    end
  end
end