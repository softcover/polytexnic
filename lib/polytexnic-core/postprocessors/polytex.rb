# encoding=utf-8
module Polytexnic
  module Postprocessor
    module Polytex

      # TODO: Support hypertarget
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
      # I.e., code that looked like
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
        code_cache.each do |key, (code, lang, in_codelisting)|
          latex = "%= lang:#{lang}\n\\begin{code}\n#{code}\n\\end{code}"
          @source.gsub!(key, latex)
        end
      end
    end
  end
end
