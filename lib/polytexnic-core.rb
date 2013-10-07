# encoding=utf-8
require "polytexnic-core/utils"
require "polytexnic-core/version"
require "polytexnic-core/postprocessor"
require "polytexnic-core/preprocessor"
require 'tempfile'
require 'nokogiri'
require 'digest/sha1'
require 'pygments'
require 'msgpack'

module Polytexnic
  module Core
    class Pipeline
      include Polytexnic::Preprocessor
      include Polytexnic::Postprocessor
      include Polytexnic::Core::Utils

      attr_accessor :literal_cache, :code_cache, :polytex, :xml, :html,
                    :math_label_cache, :highlight_cache, :maketitle_elements

      def initialize(source, options = {})
        @literal_cache = {}
        @code_cache = {}
        @maketitle_elements = {}
        @highlight_cache_filename = '.highlight_cache'
        if File.exist?(@highlight_cache_filename)
          content = File.read(@highlight_cache_filename)
          @highlight_cache = MessagePack.unpack(content) unless content.empty?
        end
        @highlight_cache ||= {}
        @math_label_cache = {}
        @source_format = options[:source] || :polytex
        @source = source
        if markdown?
          preprocess(:polytex)
          postprocess(:polytex)
        end
        @polytex = @source
      end

      def to_html
        if profiling?
          require 'ruby-prof'
          RubyProf.start
        end

        preprocess(:html)
        postprocess(:html)
        puts @html if debug?

        if profiling?
          result = RubyProf.stop
          printer = RubyProf::GraphPrinter.new(result)
          printer.print(STDOUT, {})
        end
        @html
      end

      def to_latex
        preprocess(:latex)
        postprocess(:latex)
        @latex
      end

      private

        def markdown?
          @source_format == :markdown || @source_format == :md
        end

        def polytex?
          @source_format == :polytex
        end
      end
  end
end
