# encoding=utf-8
require "polytexnic/utils"
require "polytexnic/version"
require "polytexnic/postprocessor"
require "polytexnic/preprocessor"
require 'tempfile'
require 'nokogiri'
require 'digest/sha1'
require 'msgpack'

module Polytexnic

  def self.style_file
    'polytexnic_commands.sty'
  end

  # Writes the contents of the custom polytexnic style file.
  # This is used by the `generate` method in the `softcover` gem.
  # We put it here because `custom.sty` lives inside `polytexnic`
  # so that core can support, e.g., '\PolyTeXnic'.
  def self.write_polytexnic_style_file(dir)
    csf = File.join(File.dirname(__FILE__), '..', style_file)
    File.write(File.join(dir, style_file), File.read(csf))
  end

  class Pipeline
    include Polytexnic::Preprocessor
    include Polytexnic::Postprocessor
    include Polytexnic::Utils

    attr_accessor :literal_cache, :code_cache, :polytex, :xml, :html,
                  :math_label_cache, :highlight_cache, :maketitle_elements,
                  :custom_commands

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
      @custom_commands = File.read(Polytexnic.style_file) rescue ''
      @custom_commands += "\n" + (options[:custom_commands] || '')
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
      @html.strip
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
