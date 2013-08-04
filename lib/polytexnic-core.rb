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

      attr_accessor :literal_cache, :code_cache, :polytex, :xml, :html,
                    :math_label_cache

      def initialize(polytex)
        @literal_cache = {}
        @code_cache = {}
        @math_label_cache = {}
        @polytex = polytex
      end

      def to_html
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

      # Returns a digest for use in labels.
      # I like to use labels of the form cha:foo_bar, but for some reason
      # Tralics removes the underscore in this case.
      def underscore_digest
        pipeline_digest(:_)
      end

      private

        # Returns a digest for passing things through the pipeline.
        def pipeline_digest(element)
          value = digest("#{Time.now.to_s}::#{element}")
          @literal_cache[element.to_s] ||= value
        end
    end
  end
end
