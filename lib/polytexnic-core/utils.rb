require 'securerandom'

module Polytexnic
  module Core
    module Utils
      extend self
      # Returns a salted hash digest of the string.
      def digest(string)
        salt = SecureRandom.base64
        Digest::SHA1.hexdigest(salt + string)
      end

      # Escapes backslashes.
      # Interpolated backslashes need extra escaping.
      # We only escape '\\' by itself, i.e., a backslash followed by spaces
      # or the end of line.
      def escape_backslashes(string)
        string.gsub(/\\(\s+|$)/) { '\\\\' + $1.to_s }
      end

      # Returns a Tralics pseudo-LaTeX XML element.
      # The use of the 'latex' flag is a hack to be able to use xmlelement
      # even when generating LaTeX, where we simply want to yield the block.
      def xmlelement(name, latex = false)
        output = (latex ? "" : "\\begin{xmlelement}{#{name}}")
        output << yield if block_given?
        output << (latex ? "" : "\\end{xmlelement}")
      end

      # Returns some new commands.
      # For example, we arrange for '\PolyTeXnic' to produce
      # the PolyTeXnic logo.
      def new_commands
        commands = <<-'EOS'
\newcommand{\PolyTeX}{Poly\TeX}
\newcommand{\PolyTeXnic}{Poly{\TeX}nic}
\def\hyperref[#1]#2{\xmlelt{a}{\XMLaddatt{target}{#1}#2}}

% Code listing environments
\usepackage{amsthm}
\newtheorem{theorem}{Theorem}
\theoremstyle{definition}
\newtheorem{codelisting}{Listing}[chapter]

        EOS
        commands
      end

      # Highlights source code.
      def highlight_source_code(document, formatter = 'html')
        document.tap do
          code_cache.each do |key, (content, language)|
            code = Pygments.highlight(content,
                                      lexer: language,
                                      formatter: formatter)
            code = horrible_backslash_kludge(code) if formatter == 'latex'
            document.gsub!(key, code)
          end
        end
      end

      # Does something horrible with backslashes.
      # OK, so the deal is that code highlighted for LaTeX contains the line
      # \begin{Verbatim}[commandchars=\\\{\}]
      # Oh crap, there are backslashes there. This means we have no chance
      # of getting things to work after interpolating,  gsubbing, and so on,
      # because in Ruby '\\foo' is the same as '\\\\foo', '\}' is '}', etc.
      # I thought I escaped (heh) this problem with the escape_backslashes method,
      # but here the problem is extremely specific. In particular,
      # \\\{\} is really \\ and \{ and \}, but Ruby doensn't know WTF to do
      # with it, and thinks that it's "\\{}", which is the same as '\{}'.
      # The solution is to replace '\\\\' with some number of backslashes.
      # How many? I literally had to just keep adding backslashes until
      # the output was correct when running `poly build:pdf`.
      def horrible_backslash_kludge(string)
        string.gsub!(/commandchars=\\\\/, 'commandchars=\\\\\\\\\\\\\\')
      end

      # Returns true if we are debugging, false otherwise
      def debug?
        true
      end
    end
  end
end