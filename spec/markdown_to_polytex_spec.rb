# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Pipeline do

  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end

  describe '#to_polytex' do
    subject(:processed_text) do
      Polytexnic::Pipeline.new(source, source: :markdown).polytex
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

      context "inline math" do
        let(:source) do <<-'EOS'
This is inline math: {$$} x^2 {/$$}.
          EOS
        end

        it { should include '\( x^2 \)' }
      end

      context "block math" do
        let(:source) do <<-'EOS'
This is block math:
{$$}
x^2
{/$$}.
          EOS
        end

        it { should resemble '\[ x^2 \]' }
      end
    end

    context "asides with internal lists" do
      let(:source) do <<-'EOS'
\begin{aside}
\label{aside:softcover_uses}
\heading{How to use Softcover}

* Producing ebooks with `softcover` and giving them away
* Producing ebooks with `softcover` and selling them from your own website

\end{aside}

        EOS
      end
      it { should include '\begin{aside}' }
      it { should_not include "\\end{aside}\n\\end{itemize}" }
    end

    describe "tables" do
      let(:source) do <<-'EOS'
\begin{table}

|**option**|**size**|**actual size**|
| k | kilobytes | (1024 bytes) |
| M | megabytes | (1024 kilobytes) |
| G | gigabytes | (1024 megabytes) |
| T | terabytes | (1024 gigabytes) |
| P | petabytes | (1024 terabytes) |
\end{table}

\begin{table}

|**option**|**size**|**actual size**|
| k | kilobytes | (1024 bytes) |
| M | megabytes | (1024 kilobytes) |
| G | gigabytes | (1024 megabytes) |
| T | terabytes | (1024 gigabytes) |
| P | petabytes | (1024 terabytes) |
\caption{A caption.}
\end{table}

        EOS
      end
      it { should include '\begin{table}' }
      it { should include '\begin{longtable}' }
      it { should_not include '\textbar' }
    end

    describe "footnotes" do
      subject do
        Polytexnic::Pipeline.new(markdown, source: :markdown).polytex
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

    describe "images" do
      subject do
        Polytexnic::Pipeline.new(markdown, source: :markdown).polytex
      end

      context "with a caption and a label" do
        let(:markdown) do <<-'EOS'
![Running the Softcover server in a separate tab.\label{fig:softcover_server}](images/figures/softcover_server.png)
          EOS
        end

        it { should include '\caption{Running the Softcover server in a separate tab.\label{fig:softcover_server}}' }
        it { should include '\image' }
        it { should_not include '\includegraphics' }
      end

      context "using an example that failed" do
        let(:markdown) do <<-'EOS'
a screenshot from [Lowdown](http://lowdownapp.com/), a web
application that developers use for organizing user stories.

![Lowdown for user stories](https://tutorials.railsapps.org/assets/learn-rails-lowdown-partial.png)

Just like Rails provides a structure for building a web application,
user stories provide a structure for organizing your product plan.
          EOS
        end

        it { should include '\caption{Lowdown for user stories}' }
        it { should include '\image{https://tutorials.railsapps.org' }
      end

    end

    context "with LaTeX containing" do

      context "a normal command" do
        let(:source) { 'This is a command: \foobar' }
        it { should include source }
      end

      context "backslash space" do
        let(:source) { 'Dr.\ No' }
        it { should include source }
      end

      context "escaped special characters" do
        let(:source) { '\% \& \$ \# \@ \_' }
        it { should include source }
      end

      context "an accented character" do
        let(:source) { "\\`{e}" }
        it { should include source }
      end

      context "a label and cross-reference" do
        let(:source) do <<-'EOS'
# Chapter One
\label{cha:one}

Chapter~\ref{cha:one}
          EOS
        end
        it { should include '\label{cha:one}' }
        it { should include 'Chapter~\ref{cha:one}' }
      end

      context "an inline equation" do
        let(:source) { '\( x \) is a variable' }
        it { should include source }
      end

      context "a centered equation" do
        let(:source) { '\[ x^2 - 2 = 0 \] is an equation' }
        it { should resemble source }
      end

      context "an equation environment" do
        let(:source) do <<-'EOS'
foo

\begin{equation}
\label{eq:maxwell}
\left.\begin{aligned}
\nabla\cdot\mathbf{E} & = \rho \\
\nabla\cdot\mathbf{B} & = 0 \\
\nabla\times\mathbf{E} & = -\dot{\mathbf{B}} \\
\nabla\times\mathbf{B} & = \mathbf{J} + \dot{\mathbf{E}}
\end{aligned}
\right\}
\quad\text{Maxwell equations}
\end{equation}

bar
          EOS
        end
        it { should resemble source }
      end

      context "a codelisting environment, including a nested command" do
        let(:source) do <<-'EOS'
\begin{codelisting}
\codecaption{Lorem \emph{ipsum}.}
\label{code:lorem}
```ruby
def foo; "bar"; end
```
\end{codelisting}
          EOS
        end
        it { should resemble '\begin{codelisting}' }
        it { should resemble '\codecaption{Lorem \emph{ipsum}.}' }
        it { should resemble '\label{code:lorem}' }
        it { should resemble '\end{codelisting}' }
      end

      context "a commented-out codelisting" do
        let(:source) do <<-'EOS'
%= foo:bar
<!--
\begin{codelisting}
\codecaption{Lorem \emph{ipsum}.}
\label{code:lorem}
```ruby
def foo; "bar"; end
```
\end{codelisting}
-->
          EOS
        end
        it { should include '%= foo:bar' }
        it { should_not resemble '\begin{codelisting}' }
      end

      context "code inclusion inside codelisting" do
        let(:source) do <<-'EOS'
\begin{codelisting}
\codecaption{Lorem ipsum.}
\label{code:lorem}
<<(/path/to/code)
\end{codelisting}
          EOS
        end
        it { should resemble '%= <<(/path/to/code)' }
      end

      context "codelisting followed by a section" do
        let(:source) do <<-'EOS'
\begin{codelisting}
\codecaption{Lorem ipsum.}
\label{code:lorem}
<<(/path/to/code)
\end{codelisting}

# Foo
          EOS
        end
        it { should resemble '\chapter{Foo}' }
      end
    end

    describe "source code" do

      context "inline" do
        let(:source) { '`foo bar`' }
        it { should include '\kode{foo bar}' }
      end

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
        it { should resemble '%= <<(/path/to/code)' }

        context "with an alternate lang and options" do
          let(:source) { '<<(/path/to/code.md, lang: text, options: "hl_lines": [1, 2], "linenos": true)' }
          it { should resemble '%= <<(/path/to/code.md, lang: text, options: "hl_lines": [1, 2], "linenos": true)' }
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

        context "with highlighting and options" do
          let(:source) do <<-EOS
```ruby, options: "hl_lines": [1, 2], "linenos": true
def foo
  "bar"
end
```
lorem
            EOS
          end

          let(:output) do <<-'EOS'
%= lang:ruby, options: "hl_lines": [1, 2], "linenos": true
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