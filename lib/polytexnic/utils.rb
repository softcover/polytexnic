# encoding=utf-8
require 'securerandom'
require 'json'

module Polytexnic
  module Utils
    extend self

    # Returns the executable for the Tralics LaTeX-to-XML converter.
    def tralics
      executable = `which tralics`.chomp
      return executable unless executable.empty?
      filename = if os_x_newer?
                   'tralics-os-x-newer'
                 elsif os_x_older?
                   'tralics-os-x-older'
                 elsif linux?
                   "tralics-#{RUBY_PLATFORM}"
                 end
      project_root = File.join(File.dirname(__FILE__), '..', '..')
      executable = File.join(project_root, 'precompiled_binaries', filename)
      output = `#{executable}`
      unless output.include?('This is tralics')
        url = 'https://github.com/softcover/tralics'
        $stderr.puts "\nError: Document not built"
        $stderr.puts "No compatible Tralics LaTeX-to-XML translator found"
        $stderr.puts "Follow the instructions at\n  #{url}\n"
        $stderr.puts "to compile tralics and put it on your path"
        exit(1)
      end
      @tralics ||= executable
    end


    # Expands '\input' command by processing & inserting the target source.
    def expand_input!(text, code_function, ext = 'md')
      text.gsub!(/^[ \t]*\\input\{(.*?)\}[ \t]*$/) do
        # Prepend a newline for safety.
        included_text = "\n" + File.read("#{$1}.#{ext}")
        code_function.call(included_text).tap do |clean_text|
          # Recursively substitute '\input' in included text.
          expand_input!(clean_text, code_function, ext)
        end
      end
    end

    # Returns true for OS X Mountain Lion (10.8) and later.
    def os_x_newer?
      os_x? && !os_x_older?
    end

    # Returns true for OS X Lion (10.7) and earlier.
    def os_x_older?
      os_x? && RUBY_PLATFORM.include?('11')
    end

    # Returns true if platform is OS X.
    def os_x?
      RUBY_PLATFORM.match(/darwin/)
    end

    # Returns true if platform is Linux.
    def linux?
      RUBY_PLATFORM.match(/linux/)
    end

    # Returns a salted hash digest of the string.
    def digest(string, options = {})
      salt = options[:salt] || SecureRandom.base64
      Digest::SHA1.hexdigest("#{salt}--#{string}")
    end

    # Returns a digest for passing things through the pipeline.
    def pipeline_digest(element)
      value = digest("#{Time.now.to_s}::#{element}")
      @literal_cache[element.to_s] ||= value
    end

    # Returns a digest for use in labels.
    # I like to use labels of the form cha:foo_bar, but for some reason
    # Tralics removes the underscore in this case.
    def underscore_digest
      pipeline_digest('_')
    end

    # Escapes backslashes.
    # Interpolated backslashes need extra escaping.
    # We only escape '\\' by itself, i.e., a backslash followed by spaces
    # or the end of line.
    def escape_backslashes(string)
      string.gsub(/\\(\s+|$)/) { '\\\\' + $1.to_s }
    end

    # Caches URLs for \href and \url commands.
    def cache_urls(doc, latex=false)
      doc.tap do |text|
        text.gsub!(/\\(href|url){(.*?)}/) do
          command, url = $1, $2
          key = digest(url)
          literal_cache[key] = url
          command == 'url' ? "\\href{#{key}}{#{url}}" : "\\href{#{key}}"
        end
      end
    end

    # Returns a Tralics pseudo-LaTeX XML element.
    # The use of the 'skip' flag is a hack to be able to use xmlelement
    # even when generating, e.g., LaTeX, where we simply want to yield the
    # block.
    def xmlelement(name, skip = false)
      output = (skip ? "" : "\\begin{xmlelement}{#{name}}")
      output << yield if block_given?
      output << (skip ? "" : "\\end{xmlelement}")
    end

    # Returns some commands for Tralics.
    # For various reasons, we don't actually want to include these in
    # the style file that gets passed to LaTeX. For example,
    # the commands with 'xmlelt' aren't even valid LaTeX; they're actually
    # pseudo-LaTeX that has special meaning to the Tralics processor.
    def tralics_commands
      base_commands = <<-'EOS'
% Commands specific to Tralics
\def\hyperref[#1]#2{\xmlelt{a}{\XMLaddatt{target}{#1}#2}}
\newcommand{\heading}[1]{\xmlelt{heading}{#1}}
\newcommand{\codecaption}[1]{\xmlelt{heading}{#1}}
\newcommand{\sout}[1]{\xmlelt{sout}{#1}}
\newcommand{\kode}[1]{\xmlelt{kode}{#1}}
\newcommand{\coloredtext}[2]{\xmlelt{coloredtext}{\AddAttToCurrent{color}{#1}#2}}
\newcommand{\coloredtexthtml}[2]{\xmlelt{coloredtexthtml}{\AddAttToCurrent{color}{#1}#2}}
\newcommand{\filepath}[1]{\xmlelt{filepath}{#1}}
\newcommand{\image}[1]{\xmlelt{image}{#1}}
\newcommand{\imagebox}[1]{\xmlelt{imagebox}{#1}}
% Ignore pbox argument, just replacing with content.
\newcommand{\pbox}[2]{#2}
% Ignore some other commands.
\newcommand{\includepdf}[1]{}
\newcommand{\newunicodechar}[2]{}
\newcommand{\extrafloats}[1]{}
      EOS
      custom_commands = <<-EOS
\\usepackage{amsthm}
\\theoremstyle{definition}
\\newtheorem{codelisting}{#{language_labels["listing"]}}[chapter]
\\newtheorem{aside}{#{language_labels["aside"]}}[chapter]
      EOS
      [base_commands, custom_commands].join("\n")
    end

    # Highlights source code.
    def highlight_source_code(document)
      if document.is_a?(String) # LaTeX
        substitutions = {}
        document.tap do
          code_cache.each do |key, (content, language, in_codelisting, options)|
            code   = highlight(key, content, language, 'latex', options)
            output = code.split("\n")
            horrible_backslash_kludge(add_font_info(output.first))
            highlight_lines(output, options)
            code = output.join("\n")
            substitutions[key] = in_codelisting ? code : framed(code)
          end
          document.gsub!(Regexp.union(substitutions.keys), substitutions)
        end
      else # HTML
        document.css('div.code').each do |code_block|
          key = code_block.content
          next unless (value = code_cache[key])
          content, language, _, options = value
          code_block.inner_html = highlight(key, content, language, 'html',
                                            options)
        end
      end
    end

    # Highlight lines (i.e., with a yellow background).
    # This is needed due to a Pygments bug that fails to highlight lines
    # in the LaTeX output.
    def highlight_lines(output, options)
      highlighted_lines(options).each do |i|
        if i > output.length - 1
          $stderr.puts "Warning: Highlighted line #{i} out of range" unless test?
          $stderr.puts output.inspect unless test?
        else
          output[i] = '\setlength{\fboxsep}{0pt}\colorbox{hilightyellow}{' +
                      output[i] + '}'
        end
      end
    end

    # Returns an array with the highlighted lines.
    def highlighted_lines(options)
      JSON.parse('{' + options.to_s + '}')['hl_lines'] || []
    end

    # Puts a frame around code.
    def framed(code)
      "\\begin{framed_shaded}\n#{code}\n\\end{framed_shaded}"
    end

    # Highlights a code sample.
    def highlight(key, content, language, formatter, options)
      require 'pygments'
      options = JSON.parse('{' + options.to_s + '}')
      if options['linenos'] && formatter == 'html'
        # Inline numbers look much better in HTML but are invalid in LaTeX.
        options['linenos'] = 'inline'
      end
      if (lines = options['hl_lines'])
        content_lines = content.split("\n")
        if lines.max > content_lines.length
          err  = "\nHighlight line(s) out of range: #{lines.inspect}\n"
          err += content
          raise err
        end
      end
      highlight_cache[key] ||= Pygments.highlight(content, lexer:     language,
                                                           formatter: formatter,
                                                           options:   options)
    end

    # Adds some verbatim font info (including size).
    # We prepend rather than replace the styles because the Pygments output
    # includes a required override of the default commandchars.
    # Since the substitution is only important in the context of a PDF book,
    # it only gets made if there's a style in the 'softcover.sty' file.
    # We also support custom overrides in 'custom_pdf.sty'.
    def add_font_info(string)
      softcover_sty  = File.join('latex_styles', 'softcover.sty')
      custom_pdf_sty = File.join('latex_styles', 'custom_pdf.sty')
      regex = '{code}{Verbatim}{(.*)}'
      styles = nil
      [softcover_sty, custom_pdf_sty].reverse.each do |filename|
        if File.exist?(filename)
          styles ||= File.read(filename).scan(/#{regex}/).flatten.first
        end
      end
      unless styles.nil?
        string.to_s.gsub!("\\begin{Verbatim}[",
                          "\\begin{Verbatim}[#{styles},")
      end
      string
    end

    # Does something horrible with backslashes.
    # OK, so the deal is that code highlighted for LaTeX contains the line
    # \begin{Verbatim}[commandchars=\\\{\}]
    # Oh crap, there are backslashes in there. This means we have no chance
    # of getting things to work after interpolating, gsubbing, and so on,
    # because in Ruby '\\foo' is the same as '\\\\foo', '\}' is '}', etc.
    # I thought I escaped (heh) this problem with the `escape_backslashes`
    # method, but here the problem is extremely specific. In particular,
    # \\\{\} is really \\ and \{ and \}, but Ruby doesn't know WTF to do
    # with it, and thinks that it's "\\{}", which is the same as '\{}'.
    # The solution is to replace '\\\\' with some number of backslashes.
    # How many? I literally had to just keep adding backslashes until
    # the output was correct when running `softcover build:pdf`.
    def horrible_backslash_kludge(string)
      string.to_s.gsub!(/commandchars=\\\\/, 'commandchars=\\\\\\\\')
    end

    # Returns true if we are debugging, false otherwise.
    # Manually change to `true` on an as-needed basis.
    def debug?
      false
    end

    # Returns true if we are profiling the code, false otherwise.
    # Manually change to `true` on an as-needed basis.
    def profiling?
      return false if test?
      false
    end

    def set_test_mode!
      @@test_mode = true
    end

    def test?
      defined?(@@test_mode) && @@test_mode
    end
  end
end
