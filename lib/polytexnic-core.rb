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
        @polytex = polytex
      end

      def to_html
        @polytex = add_commands(polytex)
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

      # Returns a digest for use in quote environments.
      def quote_digest
        @quote_digest ||= digest(Time.now.to_s)
      end

      # Returns a digest for use in verse environments.
      def verse_digest
        @verse_digest ||= digest(Time.now.to_s)
      end

      # Returns true if we are debugging, false otherwise
      def debug?
        false
      end
    end
  end
end
