# encoding=utf-8
require "polytexnic-core/version"
require "polytexnic-core/postprocessor"
require "polytexnic-core/preprocessor"
require 'tempfile'
require 'nokogiri'
require 'digest/sha1'
require 'pygments'

module Polytexnic
  module Core
    class Pipeline
      include Polytexnic::Preprocessor
      include Polytexnic::Postprocessor

      attr_accessor :literal_cache, :code_cache, :polytex, :xml, :html

      def initialize(polytex)
        @literal_cache = {}
        @code_cache = {}
        @polytex = polytex
      end

      def to_html
        preprocess
        postprocess
        @html
      end

      def to_latex
        highlighted(@polytex)
      end

      # Replaces code listings with highlighted versions.
      def highlighted(latex)
        lines = latex.split("\n")
        output = []
        while (line = lines.shift) do
          if line =~ /%=\s+lang:(\w+)/
            language = $1
            count = 0
            code = []
            while (line = lines.shift) do
              if line =~ /^\s*\\begin{code}\s*$/
                count += 1
              elsif line =~ /^\s*\\end{code}\s*/
                count -= 1
                if count == 0
                  output << Pygments.highlight(code.join("\n"), 
                                               lexer: language,
                                               formatter: 'latex')
                end
              else
                code << line
              end
            end
          else
            output << line
          end
        end
        output.join("\n")        
      end
    end
  end
end
