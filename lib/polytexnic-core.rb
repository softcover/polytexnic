# encoding=utf-8
require "polytexnic-core/utils"
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
        @polytex = add_commands(polytex)
      end

      def to_html
        preprocess(:html)
        postprocess(:html)
        @html
      end

      def to_latex
        preprocess(:latex)
        postprocess(:latex)
        @latex
      end


      # Adds some default commands.
      def add_commands(polytex) 
        new_commands + polytex
      end

      # Returns some new commands.
      # For example, we arrange for '\PolyTeXnic' to produce
      # the PolyTeXnic logo.
      def new_commands
        commands = <<-'EOS'
\newcommand{\PolyTeX}{Poly\TeX}
\newcommand{\PolyTeXnic}{Poly{\TeX}nic}
        EOS
        commands + "\n"
      end
    end
  end
end
