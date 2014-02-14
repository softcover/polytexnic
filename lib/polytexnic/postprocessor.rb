# encoding=utf-8
require 'cgi'
require 'polytexnic/postprocessors/html'
require 'polytexnic/postprocessors/latex'
require 'polytexnic/postprocessors/polytex'

module Polytexnic
  module Postprocessor
    include Html
    include Latex
    include Polytex

    def postprocess(format)
      case format
      when :html
        @html = xml_to_html(@xml)
      when :latex
        hyperrefs(@polytex)
        raw_source = replace_hashes(@polytex)
        @latex = highlight_source_code(raw_source)
      when :polytex
        remove_hypertarget
        fix_verbatim_bug
        write_polytex_code
      end
    end
  end
end