module CodeInclusion
  class CodeInclusionException < Exception; end;
  class RetrievalException     < CodeInclusionException; end;
  class SubsetException        < CodeInclusionException; end;


  # Converts the CodeInclusion line to a set of arguments, i.e.:
  # '%= <<(file.rb[6-14,37], git: {repo: repo_path/.git, tag: 1.0}, lang: tex, options: "hl_lines": [5]))'
  # becomes:
  #   Args#retrieval
  #    { filename:     "file.rb",
  #      line_numbers: "6-14,37",
  #      git:          { tag:  '1.0', repo: 'repo_path/.git' }
  #    }
  #   Args#render
  #    { custom_language:  "tex",
  #      highlight:        ', options: "hl_lines": [5])'}
  #
  # and
  # '%= <<(file.rb[section_x], git: {tag: 1.0}'
  # becomes:
  #   Args#retrieval
  #    { filename:     "file.rb",
  #      section:      "section_x",
  #      git:          { tag:  '1.0'}
  #    }
  #   Args#render
  #    { }
  #
  #
  # Notes for retrieval args
  #    filename is required
  #
  #    line_numbers/section names are specified in [] following the filename,
  #      foo.rb[1,4-6,8,14] or foo.rb[section_x]
  #      Thus, line_numbers and section names are mutually exclusive.
  #
  #    keyword git: is optional and within it
  #
  #      keyword tag: is optional
  #        If present tag refers to an existing tag in the repo.
  #        Tags may optionally quoted.
  #
  #      keyword repo: is optional
  #        If present it contains the full path to a git repo,
  #          full/path/to/repo/.git
  #        If absent, git commands default to the current repository.
  #        Repos may be optionally quoted.
  #
  # TODO we're dying for a real parser here.
  class Args
    CODE_REGEX =
     /^\s*%=\s+<<\s*\(                          # opening
       \s*([^\s]+?)                             # path to file
       (?:\[(.+?)\])?                           # optional section, line numbers
       (?:,\s*git:\s*([ ,"'\w\.\/\-\{\}:]+?))?  # optional git tag, repo
       (?:,\s*lang:\s*(\w+))?                   # optional lang
       (,\s*options:\s*.*)?                     # optional options
       \s*\)                                    # closing paren
       /x

    attr_reader :input, :retrieval, :render, :match

    def initialize(input)
      @input     = input
      @retrieval = {}
      @render    = {}
      @match     = parse

      extract
    end

    def parse
      CODE_REGEX.match(input)
    end

    def extract
      return unless code_inclusion_line?

      retrieval[:filename]       = match[1]

      if specifies_line_numbers?
        retrieval[:line_numbers] = match[2]
      elsif specifies_section?
        retrieval[:section]      = match[2]
      end

      retrieval[:git]            = extract_git(match[3]) if match[3]

      render[:custom_language]   = match[4]
      render[:highlight]         = match[5]
    end

    def code_inclusion_line?
      !match.nil?
    end

    def specifies_section?
      match[2] && !specifies_line_numbers?
    end

    def specifies_line_numbers?
      whitespace_digits_dashes_and_commas.match(match[2])
    end

    def extract_git(git_args)
      { tag:  extract_git_option('tag',  git_args),
        repo: extract_git_option('repo', git_args)}
    end

    def extract_git_option(keyword, args)
      if (match = git_option_regex(keyword).match(args))
        match[1]
      end
    end

    def git_option_regex(keyword)
      /#{start}#{keyword}:#{space}#{quote}(.*?)#{quote}#{finish}/
    end

    def start
      "\.*?"
    end

    def space
      "\s?"
    end

    # single or double quotes are optional but permitted
    def quote
      %q[(?:"|')?]
    end

    # comma or } (with optional leading space) ends things
    def finish
      "\s?(,|})"
    end

    def whitespace_digits_dashes_and_commas
      /^\s*\d[-,\d\s]*$/
    end
  end


  class Code
    DEFAULT_LANGUAGE = 'text'

    # Returns an instance of CodeInclusion::Code or nil
    def self.for(line)
      args = Args.new(line)
      new(args.retrieval, args.render) if args.code_inclusion_line?
    end

    attr_reader :retrieval_args, :render_args

    def initialize(retrieval_args, render_args)
      @retrieval_args, @render_args = retrieval_args, render_args
    end

    # Returns the formatted code or an error message
    def to_s
      return unless filename

      result = []
      result << "%= lang:#{language}#{highlight}"
      result << '\begin{code}'
      result.concat(raw_code)
      result << '\end{code}'

      rescue CodeInclusionException => e
        code_error(e.message)
    end

    private

    def raw_code
      Listing.for(retrieval_args)
    end

    def filename
      retrieval_args[:filename]
    end

    def highlight
      render_args[:highlight]
    end

    def custom_language
      render_args[:custom_language]
    end

    def language_from_extension
      extension_array     = File.extname(filename).scan(/\.(.*)/).first
      lang_from_extension = extension_array.nil? ? nil : extension_array[0]
    end

    def language
      (custom_language || language_from_extension || DEFAULT_LANGUAGE)
    end

    def code_error(details)
      ["\\verb+ERROR: #{details}+"]
    end
  end

  # Listing.for takes a set of retrieval args and returns an array of
  #   source code lines to be included in the book.
  #
  # Listing is responsible for retrieving the file you're including
  # (the 'FullListing') and for extracting individual lines from that file
  # (the 'Subset').

  # It contains factory methods to choose the correct FullListing and Subset
  # classes and the code to wire them together.  If you add new FullListing or
  # Subset objects, you'll need to wire them together here.
  class Listing

    # Returns the lines of code to be included or
    #   an exception containing the error message.
    def self.for(args)
      new(args).final_listing
    end

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def final_listing
      subset_class.new(full_listing, args).lines

      rescue SubsetException => e
        raise RetrievalException.new(e.message +
                                     " in file '#{args[:filename]}'")
    end

    private

    def full_listing
      retrieval_class.new(args).lines
    end

    def retrieval_class
      case
      when args[:git]
        FullListing::GitTag
      else
        FullListing::File
      end
    end

    def subset_class
      case
      when args[:line_numbers]
        Subset::LineNumber
      when args[:section]
        Subset::Section
      else
        Subset::Everything
      end
    end
  end


  # FullListing objects retrieve an entire file from some location.
  module FullListing

    # Return lines contained in a file read from disk.
    class File
      attr_reader :filename

      def initialize(args)
        @filename = args[:filename]
      end

      def lines
        ensure_exists!
        ::File.read(filename).split("\n")
      end

      private

      def ensure_exists!
        unless ::File.exist?(filename)
         raise(RetrievalException, "File '#{filename}' does not exist")
        end
      end
    end

    # Return lines contained in a file that's tagged in git.
    class GitTag

      def self.git_cmd
        GitCmd.new
      end

      attr_reader :filename, :tag, :repository, :git_cmd

      def initialize(args, git_cmd=self.class.git_cmd)
        @filename   = args[:filename]
        @tag        = args[:git][:tag]
        @repository = args[:git][:repo]

        @git_cmd  = git_cmd

        git_cmd.repository = repository
        git_cmd.tagname    = tag
        git_cmd.filename   = filename
      end

      def lines
        ensure_exists!
        result = git_cmd.show

        if git_cmd.succeeded?
          result.split("\n")
        else
          raise(RetrievalException, result)
        end
      end

      private

      def ensure_exists!
        unless git_cmd.repository_exists?
          raise(RetrievalException, "Repository '#{repository}' does not exist.")
        end
        unless git_cmd.tag_exists?
          raise(RetrievalException, "Tag '#{tag}' does not exist.")
        end
      end

      class GitCmd
        attr_accessor :repository, :tagname, :filename

        def show
          `git #{git_dir} show #{tagname}:#{filename}`
        end

        def succeeded?
          $? == 0
        end

        def tags
          `git #{git_dir} tag`
        end

        def log
          `git #{git_dir} log -1`
        end

        def git_dir
          %Q[--git-dir="#{repository}"] if repository
        end

        def repository_exists?
          !log.include?("Not a git repository")
        end

        def tag_exists?
          tags.split("\n").include?(tagname)
        end
      end
    end
  end


  # Subsets reduce an input array of strings to a subset of that array.
  module Subset

    # Return the lines in the named section.
    class Section
      attr_reader :input, :name

      def initialize(input, args)
        @input = input
        @name  = args[:section]
      end

      def lines
        ensure_exists!
        input.slice(index_of_first_line, length)
      end

      private

      def exist?
        !!index_of_begin
      end

      def index_of_begin
        @section_begin_i ||=
          input.index {|line| clean(line) == begin_text }
      end

      def index_of_first_line
        @first_line_i ||= index_of_begin + 1
      end

      def length
        input.slice(index_of_first_line, input.size).index { |line|
          clean(line) == (end_text)
        }
      end

      def marker
        '#//'
      end

      def begin_text
        "#{marker} begin #{name}"
      end

      def end_text
        "#{marker} end"
      end

      def clean(str)
        str.strip.squeeze(" ")
      end

      def ensure_exists!
        unless exist?
          section_err = "Could not find section header '#{begin_text}'"
          raise(SubsetException, section_err)
        end
      end
    end

    # Return the lines specified by :line_numbers.
    # Line numbers are comma separated and may contain ranges, i.e.,
    #   2, 4-6, 8, 14
    #
    # Rules:
    #   whitespace is ignored
    #   ranges are included in ascending order (4-6 is the same as 6-4)
    #   lines numbers higher than the max available are ignored
    class LineNumber
      attr_reader :input, :numbers
      def initialize(input, args)
        @input   = input
        @numbers = args[:line_numbers]
      end

      def lines
        individual_numbers.collect {|i| input[i - 1]}.compact
      end

      private

      def individual_numbers
        clumps.collect {|clump| expand_clump(clump)}.flatten
      end

      def clumps
        numbers.gsub(/ /,'').split(",")
      end

      def expand_clump(clump)
        edges = clump.split('-').collect(&:to_i)
        (edges.min.to_i..edges.max.to_i).to_a
      end
    end

    # Return everything (think of this as the null object subset)
    class Everything
      attr_reader :input

      def initialize(input, _=nil)
        @input = input
      end

      def lines
        input
      end
    end
  end
end
