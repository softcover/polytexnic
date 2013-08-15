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
        format = options[:format] || :polytex
        @polytex = case format
                   when :polytex
                     source
                   when :markdown
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

      def to_polytex(markdown)
        pandoc_polytex(markdown)
      end

      def pandoc_polytex(markdown)
        file = Tempfile.new(['markdown', '.md'])
        puts markdown if debug?
        file.write(markdown)
        file.close
        Dir.mkdir 'log' unless File.directory?('log')
        exec = `which pandoc`.strip
        polytex_filename = file.path.sub('.md', '.tex')
        system("#{exec} -s #{file.path} -o #{polytex_filename}")
        dirname = File.dirname(file.path)
        raw_polytex = File.read(polytex_filename)
        # xml = clean_xml(raw_xml)
        polytex = raw_polytex
        puts polytex if debug?
        polytex
      ensure
        # xmlfile = file.path.sub('.tex', '.xml')
        # logfile = file.path.sub('.tex', '.log')
        # [xmlfile, logfile].each do |file|
        #   File.delete(file) if File.exist?(file)
        # end
        file.delete
        File.delete(polytex_filename)
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
