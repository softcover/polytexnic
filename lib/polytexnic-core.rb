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
        puts @html if debug?
        @html
      end

      def to_latex
        preprocess(:latex)
        postprocess(:latex)
        @latex
      end

      # Adds some default commands.
      # The new_commands are currently in utils, but probably should
      # eventually be refactored into a file.
      def add_commands(polytex)
        new_commands + polytex
      end

      # Returns a digest for use in quote environments.
      def quote_digest
        pipeline_digest(:quote)
      end

      # Returns a digest for use in verse environments.
      def verse_digest
        pipeline_digest(:verse)
      end

      # Returns a digest for use in labels.
      # I like to use labels of the form cha:foo_bar, but for some reason
      # Tralics removes the underscore in this case.
      def underscore_digest
        pipeline_digest(:_)
      end

      private

        # Returns a digest for passing things through the pipeline.
        # The principal cases are the quote and verse environment,
        # which Tralics handles incorrectly. As a kludge, we run a
        # tag through the pipeline and gsub it at the end. In order to ensure
        # that the gsub is safe, the tag should be unique.
        def pipeline_digest(element)
          @literal_cache[element] ||= digest("#{Time.now.to_s}::#{element}")
        end
    end
  end
end
