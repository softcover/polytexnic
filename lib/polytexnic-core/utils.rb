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
        EOS
        commands + "\n"
      end

      # Highlights source code.
      def highlight_source_code(document, formatter = 'html')
        document.tap do
          code_cache.each do |key, (content, language)|
            code = Pygments.highlight(content,
                                      lexer: language,
                                      formatter: formatter)
            document.gsub!(key, code)
          end
        end
      end

      # Returns true if we are debugging, false otherwise
      def debug?
        false
      end
    end
  end
end