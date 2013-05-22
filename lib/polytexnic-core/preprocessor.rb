# encoding=utf-8
require 'polytexnic-core/literal'
require 'polytexnic-core/preprocessors/html'
require 'polytexnic-core/preprocessors/latex'

module Polytexnic
  module Preprocessor
    include Literal
    include Html
    include Latex

    # Preprocesses the input PolyTeX based on output format.
    def preprocess(format)
      if format == :html
        to_xml
      elsif format == :latex
        to_hashed_latex
      end
    end
  end
end
