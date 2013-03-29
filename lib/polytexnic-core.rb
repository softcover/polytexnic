# encoding=utf-8
require "polytexnic-core/version"
require "polytexnic-core/postprocessor"
require "polytexnic-core/preprocessor"
require 'tempfile'
require 'nokogiri'
require 'digest/sha1'

module Polytexnic
  module Core
    class Pipeline
      include Polytexnic::Preprocessor
      include Polytexnic::Postprocessor

      attr_accessor :literal_cache, :polytex, :xml, :html

      def initialize(polytex)
        @literal_cache = {}
        @polytex = polytex
      end

      def to_html
        preprocess
        postprocess
        @html
      end

    end
  end
end
