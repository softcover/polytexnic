# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do

  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end

  describe '#to_polytex' do
    subject(:processed_text) do
      Polytexnic::Core::Pipeline.new(source, source: :markdown).polytex
    end

    context "for vanilla Markdown" do
      let(:source) { '*foo* **bar**' }
      it { should include '\emph{foo} \textbf{bar}' }
      it { should_not include '\begin{document}' }
    end

    context "for multiline Markdown" do
      let(:source) do <<-EOS
# A chapter

Hello, *world*!

## A section

Lorem ipsum
        EOS
      end
      it { should include '\chapter{A chapter}' }
      it { should include '\section{A section}' }
      it { should_not include '\hypertarget' }
    end

    describe "with math" do
      subject do
        Polytexnic::Core::Pipeline.new(markdown, source: :markdown).polytex
      end

      context "inline math" do
        let(:markdown) do <<-'EOS'
This is inline math: {$$} x^2 {/$$}.
          EOS
        end

        it { should include '\( x^2 \)' }
      end

      context "block math" do
        let(:markdown) do <<-'EOS'
This is block math:
{$$}
x^2
{/$$}.
          EOS
        end

        it { should resemble '\[ x^2 \]' }
      end
    end

    describe "footnotes" do
      subject do
        Polytexnic::Core::Pipeline.new(markdown, source: :markdown).polytex
      end

      context "first chapter with footnotes" do
        let(:markdown) do <<-'EOS'
To add a footnote, you insert a footnote tag like this.[^foo]

Then you add the footnote content later in the text, using the same tag,
with a colon and a space:[^foo2]

[^foo]: This is the footnote content.

That is it.  You can keep writing your text after the footnote content.

[^foo2]: This is the footnote text. We are now going to add a second line
    after typing in four spaces.
          EOS
        end

        it { should include '\footnote{This is the footnote content.}' }
        it { should include 'after typing in four spaces.}' }
      end
    end

    describe "source code" do
      context "without highlighting" do
        let(:source) do <<-EOS
    def foo
      "bar"
    end
          EOS
        end
        let(:output) do <<-'EOS'
\begin{verbatim}
def foo
  "bar"
end
\end{verbatim}
          EOS
        end
        it { should eq output }
      end

      context "with highlighting" do
        let(:source) do <<-EOS
{lang="ruby"}
    def foo
      "bar"
    end
lorem
          EOS
        end
        let(:output) do <<-'EOS'
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}
lorem
          EOS
        end
        it { should resemble output }
      end

      describe "code inclusion" do
        let(:source) { '<<(/path/to/code)' }
        it { should resemble '%= <</path/to/code' }

        context "with an alternate lang" do
          let(:source) { '<<(/path/to/code.md, lang: text)' }
          it { should resemble '%= <</path/to/code.md, lang: text' }
        end
      end

      describe "GitHub-flavored code fencing" do

        context "without highlighting" do
          let(:source) do <<-EOS
```
def foo
  "bar"
end
```
lorem
            EOS
          end

          let(:output) do <<-'EOS'
\begin{verbatim}
def foo
  "bar"
end
\end{verbatim}
lorem
            EOS
          end
          it { should resemble output }
        end

        context "with highlighting" do
          let(:source) do <<-EOS
```ruby
def foo
  "bar"
end
```
lorem
            EOS
          end

          let(:output) do <<-'EOS'
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}
lorem
            EOS
          end
          it { should resemble output }
        end
      end
    end
  end
end