# encoding=utf-8
require 'polytexnic-core/literal'
require 'polytexnic-core/preprocessors/html'
require 'polytexnic-core/preprocessors/latex'
require 'polytexnic-core/preprocessors/polytex'

module Polytexnic
  module Preprocessor
    include Literal
    include Html
    include Latex
    include Polytex

    # Preprocesses the input based on output format.
    def preprocess(format)
      case format
      when :html    then to_xml
      when :latex   then to_processed_latex
      when :polytex then to_polytex
      end
    end
  end
end
