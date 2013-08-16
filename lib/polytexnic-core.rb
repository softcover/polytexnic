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
        # then run everything through the PolyTeX pipeline. Happily, kramdown
        # comes equipped with a `to_latex` method that does most of the heavy
        # lifting. The ouput isn't as clean as that produced by Pandoc (our
        # previous choice), but it comes with significant advantages: (1) It's
        # written in Ruby, available as a gem, so its use eliminates an external
        # dependency. (2) It's the foundation for the "Markdown" interpreter
        # used by Leanpub, so by using it ourselves we ensure greater
        # compatibility with Leanpub books.
        #
        # * <rant>The number of mutually incompatible markup languages going
        # by the name "Markdown" is truly mind-boggling. Most of them add things
        # to John Gruber's original Markdown language in an ever-expanding
        # attempt to bolt on the functionality needed to write longer documents
        # (but why not just use LaTeX?). At this point, I fear that "Markdown"
        # has become little more than a marketing term.</rant>
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
