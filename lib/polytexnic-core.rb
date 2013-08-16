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
                    :math_label_cache, :highlight_cache

      def initialize(source, options = {})
        @literal_cache = {}
        @code_cache = {}
        @highlight_cache_filename = f = '.highlight_cache'
        @highlight_cache = File.exist?(f) ? MessagePack.unpack(File.read(f))
                                          : {}
        @math_label_cache = {}
        @format = options[:format] || :polytex
        @polytex = case
                   when polytex?
                     source
                   when markdown?
                     to_polytex(source)
                   end
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
          @format == :markdown || @format == :md
        end

        def polytex?
          @format == :polytex
        end

        # Converts Markdown to PolyTeX.
        # We adopt a unified approach: rather than convert "Markdown" (I use
        # the term loosely*) directly to HTML, we convert it to PolyTeX and
        # then run everything through the PolyTeX pipeline.
        # * <rant>The number of mutually incompatible markup languages going
        # by the name "Markdown" is truly mind-boggling. At this point, I fear
        # "Markdown" is little more than a marketing term.</rant>
        def to_polytex(markdown)
          require 'kramdown'
          lh = 'chapter,section,subsection,subsubsection,paragraph,subparagraph'
          polytex = Kramdown::Document.new(markdown, latex_headers: lh).to_latex
          # TODO: Put this in a postprocessor.
          polytex.gsub(/\\hypertarget.*$/, '')
        end
      end
  end
end
