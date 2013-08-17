# encoding=utf-8
module Polytexnic
  module Postprocessor
    module Polytex

      def sub_things
        @source.tap do |s|
          s.gsub!(/\\hypertarget.*$/, '')
          s.gsub!(/\\begin\{verbatim\}/) { |s| s + "\n" }
        end
      end
    end
  end
end
