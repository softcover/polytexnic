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
      include Polytexnic::Core::Utils

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
        if File.exist?('polytexnic_commands.sty')
          # This is the case when used with the full PolyTeXnic system,
          # where we don't want to add the commands to each LaTeX fragment.
          polytex
        else
          new_commands + polytex
        end
      end
    end
  end
end
