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

  # Returns style file (including absolute path) within the gem.
  def self.core_style_file
    File.join(File.dirname(__FILE__), '..', style_file)
  end

  # Writes the contents of the custom polytexnic style file.
  # This is used by the `generate` method in the `softcover` gem.
  # We put it here because `polytexnic_commands.sty` lives inside `polytexnic`
  # so that core can support, e.g., '\PolyTeXnic'.
  def self.write_polytexnic_style_file(dir)
    File.write(File.join(dir, style_file), File.read(self.core_style_file))
  end

  class Pipeline
    include Polytexnic::Preprocessor
    include Polytexnic::Postprocessor
    include Polytexnic::Utils

    attr_accessor :literal_cache, :code_cache, :polytex, :xml, :html,
                  :math_label_cache, :highlight_cache, :maketitle_elements,
                  :custom_commands, :language_labels

    def initialize(source, options = {})
      @literal_cache = options[:literal_cache] || {}
      @code_cache = {}
      @maketitle_elements = {}
      @language_labels = options[:language_labels] || default_language_labels
      @highlight_cache_filename = '.highlight_cache'
      if File.exist?(@highlight_cache_filename)
        content = File.read(@highlight_cache_filename)
                      .force_encoding('ASCII-8BIT')
        begin
          @highlight_cache = MessagePack.unpack(content) unless content.empty?
        rescue MessagePack::UnpackError
          FileUtils.rm @highlight_cache_filename
        end
      end
      @highlight_cache ||= {}
      @math_label_cache = {}
      @source_format = options[:source] || :polytex
      @custom_commands = File.read(Polytexnic.core_style_file) rescue ''
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
      puts "\nafter preprocess:\n#{@xml}" if debug?
      postprocess(:html)
      puts "\nafter postprocess:\n#{@html}" if debug?

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

      # Returns the default labels for 'Chapter', 'Figure', etc.
      def default_language_labels
        {"chapter"=>{"word"=>"Chapter", "order"=>"standard"},
         "table"=>"Table",
         "figure"=>"Figure",
         "aside"=>"Box",
         "listing"=>"Listing",
         "equation"=>"Equation",
         "eq"=>"Eq",
         "contents"=>"Contents"
       }
      end

      def markdown?
        @source_format == :markdown || @source_format == :md
      end

      def polytex?
        @source_format == :polytex
      end
    end
end
