require 'securerandom'

module Polytexnic
  module Core
    module Utils
      extend self
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

      # Returns a Tralics pseudo-LaTeX XML element.
      # The use of the 'skip' flag is a hack to be able to use xmlelement
      # even when generating, e.g., LaTeX, where we simply want to yield the
      # block.
      def xmlelement(name, skip = false)
        output = (skip ? "" : "\\begin{xmlelement}{#{name}}")
        output << yield if block_given?
        output << (skip ? "" : "\\end{xmlelement}")
      end

      # Returns the executable on the path.
      def executable(name, message = nil)
        if (exec = `which #{name}`.chomp).empty?
          dir = Gem::Specification.find_by_name('polytexnic-core').gem_dir
          binary = File.join(dir, 'precompiled_binaries', name)
          # Try a couple of common directories for executables.
          if File.exist?(bin_dir = File.join(ENV['HOME'], 'bin'))
            FileUtils.cp binary, bin_dir
          elsif File.exist?(bin_dir = File.join('/', 'usr', 'local', 'bin'))
            FileUtils.cp binary, bin_dir
          else
            message ||= "File '#{name}' not found"
            $stderr.puts message
            exit 1
          end
          executable(name, message)
        else
          exec
        end
      end

      # Returns some new commands.
      # For example, we arrange for '\PolyTeXnic' to produce
      # the PolyTeXnic logo.
      def tralics_commands
        <<-'EOS'
% Commands specific to Tralics
\def\hyperref[#1]#2{\xmlelt{a}{\XMLaddatt{target}{#1}#2}}
\newcommand{\heading}[1]{\xmlelt{heading}{#1}}
\newcommand{\kode}[1]{\xmlelt{kode}{#1}}
        EOS
      end
      def new_commands
        <<-'EOS'
\newcommand{\PolyTeX}{Poly\TeX}
\newcommand{\PolyTeXnic}{Poly{\TeX}nic}

% Codelisting and similar environments
\usepackage{amsthm}
\newtheorem{theorem}{Theorem}
\theoremstyle{definition}
\newtheorem{codelisting}{Listing}[chapter]
\newtheorem{aside}{Box}[chapter]
        EOS
      end

      # Highlights source code.
      def highlight_source_code(document)
        if document.is_a?(String) # LaTeX
          substitutions = {}
          document.tap do
            code_cache.each do |key, (content, language)|
              code = highlight(key, content, language, 'latex')
              output = code.split("\n")
              horrible_backslash_kludge(add_font_info(output.first))
              code = output.join("\n")
              substitutions[key] = "\\begin{framed_shaded}\n" + code +
                                   "\n\\end{framed_shaded}"
            end
            document.gsub!(Regexp.union(substitutions.keys), substitutions)
          end
        else # HTML
          document.css('div.code').each do |code_block|
            key = code_block.content
            next unless (value = code_cache[key])
            content, language = value
            code_block.inner_html = highlight(key, content, language, 'html')
          end
        end
      end

      # Highlights a code sample.
      def highlight(key, content, language, formatter)
        highlight_cache[key] ||= Pygments.highlight(content,
                                                    lexer: language,
                                                    formatter: formatter)
      end

      # Adds some verbatim font info (including size).
      def add_font_info(string)
        string.gsub!('\begin{Verbatim}[',
                     '\begin{Verbatim}[fontsize=\relsize{-1.5},fontseries=b,')
      end

      # Does something horrible with backslashes.
      # OK, so the deal is that code highlighted for LaTeX contains the line
      # \begin{Verbatim}[commandchars=\\\{\}]
      # Oh crap, there are backslashes in there. This means we have no chance
      # of getting things to work after interpolating, gsubbing, and so on,
      # because in Ruby '\\foo' is the same as '\\\\foo', '\}' is '}', etc.
      # I thought I escaped this problem with the escape_backslashes method,
      # but here the problem is extremely specific. In particular,
      # \\\{\} is really \\ and \{ and \}, but Ruby doensn't know WTF to do
      # with it, and thinks that it's "\\{}", which is the same as '\{}'.
      # The solution is to replace '\\\\' with some number of backslashes.
      # How many? I literally had to just keep adding backslashes until
      # the output was correct when running `poly build:pdf`.
      def horrible_backslash_kludge(string)
        string.gsub!(/commandchars=\\\\/, 'commandchars=\\\\\\\\')
      end

      # Returns true if we are debugging, false otherwise
      def debug?
        true
      end

      # Returns true if we are profiling the code, false otherwise.
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
end