# encoding=utf-8
module Polytexnic
  module Postprocessor
    module Polytex

      # Removes references to the hypertarget package.
      # TODO: Support hypertarget
      # This isn't a priority, as you get most of what you need
      # with hyperref.
      def remove_hypertarget
        @source.gsub!(/\\hypertarget.*$/, '')
      end

      # Fixes a kramdown verbatim bug.
      # When converting code, kramdown outputs
      # "\begin{verbatim}foo" instead of
      # "\begin{verbatim}\nfoo".
      def fix_verbatim_bug
        @source.gsub!(/\\begin\{verbatim\}/) { |s| s + "\n" }
      end

      # Writes the PolyTeX code environments based on the code cache.
      # I.e., code that looks like
      # {lang="ruby"}
      #     def foo
      #       "bar"
      #     end
      # becomes
      # %= lang:ruby
      # \begin{code}
      # def foo
      #   "bar"
      # end
      # \end{code}
      # which reduces syntax highlighting to a previously solved problem.
      def write_polytex_code
        code_cache.each do |key, (code, lang, in_codelisting, options)|
          # puts '*********'
          # puts @source.inspect
          # raise code.inspect
          latex = "%= lang:#{lang}#{options}\n" +
                  "\\begin{code}\n" + escape_hack(code) + "\n\\end{code}"
          @source.gsub!(key, latex)
        end
      end

      # Hacks some backslash escapes.
      # Seriously, WTF is up with backslashes?
      def escape_hack(string)
        string.gsub('\\', '\\\\\\')
      end
    end
  end
end
