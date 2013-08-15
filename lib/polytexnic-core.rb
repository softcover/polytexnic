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

        def to_polytex(markdown)
          pandoc_polytex(markdown)
        end

        def pandoc_polytex(markdown)
          file = Tempfile.new(['markdown', '.md'])
          puts markdown if debug?
          file.write(markdown)
          file.close
          polytex_filename = file.path.sub('.md', '.tex')
          system("#{pandoc} -s #{file.path} -o #{polytex_filename}")
          raw_polytex =
          polytex = File.read(polytex_filename)
          puts polytex if debug?
          polytex
        ensure
          file.delete
          File.delete(polytex_filename)
        end

        # Returns the executable for Pandoc.
        def pandoc
          executable('pandoc')
        end
      end
  end
end
