# encoding=utf-8
module Polytexnic
  module Preprocessor
    module Polytex

      # Converts Markdown to PolyTeX.
      # We adopt a unified approach: rather than convert "Markdown" (I use
      # the term loosely*) directly to HTML, we convert it to PolyTeX and
      # then run everything through the PolyTeX pipeline. Happily, kramdown
      # comes equipped with a `to_latex` method that does most of the heavy
      # lifting. The ouput isn't as clean as that produced by Pandoc (our
      # previous choice), but it comes with significant advantages: (1) It's
      # written in Ruby, available as a gem, so its use eliminates an external
      # dependency. (2) It's the foundation for the "Markdown" interpreter
      # used by Leanpub, so by using it ourselves we ensure greater
      # compatibility with Leanpub books.
      #
      # * <rant>The number of mutually incompatible markup languages going
      # by the name "Markdown" is truly mind-boggling. Most of them add things
      # to John Gruber's original Markdown language in an ever-expanding
      # attempt to bolt on the functionality needed to write longer documents
      # (but why not just use LaTeX?). At this point, I fear that "Markdown"
      # has become little more than a marketing term.</rant>
      def to_polytex
        require 'kramdown'
        # preprocess(:polytex)
        # postprocess(:polytex)
        lh = 'chapter,section,subsection,subsubsection,paragraph,subparagraph'
        @source = Kramdown::Document.new(@source, latex_headers: lh).to_latex
      end
    end
  end
end