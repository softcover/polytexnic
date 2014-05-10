module CodeInclusion
  class CodeInclusionException < Exception; end;

  class Code
    CODE_REGEX = /^\s*%=\s+<<\s*\(                # opening
                   \s*([^\s]+?)                   # path to file
                   (?:\[(.+?)\])?                 # optional section name
                   (?:,\s*tag:\s*([\w\.\/\-]+?))? # optional git tag
                   (?:,\s*lang:\s*(\w+))?         # optional lang
                   (,\s*options:\s*.*)?           # optional options
                   \s*\)                          # closing paren
                   /x

    DEFAULT_LANGUAGE = 'text'

    # Returns an instance of CodeInclusion::Code or nil
    def self.for(line)
      if (line =~ CODE_REGEX)
        opts = {}
        opts[:tag]             = $3
        opts[:custom_language] = $4
        opts[:highlight]       = $5
        new($1, $2, opts)
      end
    end

    attr_reader :filename, :sectionname, :opts

    def initialize(filename, sectionname, opts)
      @filename    = filename
      @sectionname = sectionname
      @opts        = opts
    end

    # Returns the formatted code or an error message
    def to_s
      return unless filename

      result = []
      result << "%= lang:#{language}#{opts[:highlight]}"
      result << '\begin{code}'
      result.concat(raw_code)
      result << '\end{code}'

      rescue CodeInclusionException => e
        code_error(e.message)
    end

    def raw_code
      reader.read
    end

    private

    # Manufacture a reader of the appriopriate type
    def reader
      @reader ||=
        if opts[:tag]
          GitTaggedFileReader.new(filename,
                                  sectionname,
                                  opts.delete(:tag),
                                  opts)
        elsif sectionname
          SectionReader.new(filename, sectionname)
        else
          FileReader.new(filename)
        end
    end

    def language
      extension_array     = File.extname(filename).scan(/\.(.*)/).first
      lang_from_extension = extension_array.nil? ? nil : extension_array[0]
      (opts[:custom_language] || lang_from_extension || DEFAULT_LANGUAGE)
    end

    def code_error(details)
      ["\\verb+ERROR: #{details}+"]
    end
  end


  # GitTaggedFileReader retrieves code from a
  # tagged file in your local git repository.
  #
  #  Example: <<(lib/polytexnic/literal.rb, tag: v0.9.4)
  class GitTaggedFileReader

    def self.git
      Git.new
    end

    attr_reader :filename, :sectionname, :tagname, :opts, :git

    def initialize(filename, sectionname, tagname, opts={}, git=self.class.git)
      @filename    = filename
      @sectionname = sectionname
      @tagname     = tagname
      @opts        = opts
      @git         = git
    end

    def read
      ensure_tag_exists!

      Dir.mktmpdir do |tmpdir|
        checkout_file!(tmpdir)
        read_file(tmpdir)
      end
    end

    private

    def ensure_tag_exists!
      unless git.tag_exists?(tagname)
        raise(CodeInclusionException, "Tag '#{tagname}' does not exist.")
      end
    end

    def checkout_file!(tmpdir)
      output = git.checkout(tmpdir, filename, tagname)
      unless git.checkout_succeeded?
        raise(CodeInclusionException, improve_error_message(output, tmpdir))
      end
    end

    def read_file(tmpdir)
      tmpfilename = File.join(tmpdir, filename)
      CodeInclusion::Code.new(tmpfilename, sectionname, opts).raw_code
    end

    def improve_error_message(msg, tmpdir)
        msg.gsub(/#{tmpdir}/, '').chomp(".\n") + " in tag #{tagname}."
    end


    class Git
      def checkout(tmpdir, filename, tagname)
        `git --work-tree=#{tmpdir} checkout #{tagname} #{filename} 2>&1`
      end

      def checkout_succeeded?
        $? == 0
      end

      def tags
        `git tag`
      end

      def tag_exists?(tagname)
        tags.split("\n").include?(tagname)
      end
    end
  end


  # FileReader retrieves code from a file on disk.
  #
  #  Example: <<(lib/polytexnic/literal.rb)
  class FileReader
    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def read
      ensure_file_exists!
      File.readlines(filename)
    end

    def ensure_file_exists!
      unless File.exist?(filename)
       raise(CodeInclusionException, "File '#{filename}' does not exist")
      end
    end
  end


  # SectionReader retrieves code from a marked section in a file on disk.
  #
  #  Example: <<(lib/polytexnic/literal.rb[my_section])
  #
  # Sections are delineated by '#// begin section_name' and '#// end',
  # for example:
  #
  #   #// begin my_section
  #   some code
  #   #// end
  class SectionReader < FileReader
    attr_reader :lines, :sectionname

    def initialize(filename, sectionname)
      super(filename)
      @sectionname = sectionname
    end

    def read
      @lines = super
      ensure_section_exists!
      lines.slice(index_of_first_line, length)
    end

    private
    def exist?
      !!index_of_section_begin
    end

    def index_of_section_begin
      @section_begin_i ||=
        lines.index { |line| clean(line) == section_begin_text }
    end

    def index_of_first_line
      @first_line_i ||= index_of_section_begin + 1
    end

    def length
      lines.slice(index_of_first_line, lines.size).index do |line|
        clean(line) == (section_end_text)
      end
    end

    # Returns the marker for marking begin/end code sections.
    def marker
      '#//'
    end

    def section_begin_text
      "#{marker} begin #{sectionname}"
    end

    def section_end_text
      "#{marker} end"
    end

    # Returns a string cleansed of superfluous whitespace.
    def clean(str)
      str.strip.squeeze(" ")
    end

    def ensure_section_exists!
      unless exist?
        section_err = "Could not find section header '#{section_begin_text}'"
        file_err    = " in file '#{filename}'"
        raise(CodeInclusionException, section_err + file_err)
      end
    end
  end
end
