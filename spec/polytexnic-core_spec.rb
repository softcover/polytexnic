# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core do
  it { should respond_to(:polytex_to_html_fragment) }

  describe '#polytex_to_html' do
    subject { Polytexnic::Core.polytex_to_html_fragment(polytex) }

    describe "italics conversion" do
      let(:polytex) { '\emph{foo bar}' }
      it { should resemble('<em>foo bar</em>') }
    end

    describe "with multiple instances" do
      let(:polytex) do
        '\emph{foo bar} and also \emph{baz quux}'
      end

      it { should resemble('<em>foo bar</em>') }
      it { should resemble('<em>baz quux</em>') }
    end

    describe "quoted strings" do
      context "with single quotes" do
        let(:polytex) { "``foo bar''" }
        it { should =~ /&#8220;foo bar&#8221;/ }
      end
    end

    describe "footnotes" do
      let(:polytex) { '\footnote{Foo}' }
      it do
        should resemble('<sup class="footnote"><a href="#footnote-1">1</a></sup>')
      end
      it do
        should resemble(
          '<div id="footnotes">' +
            '<div id="footnote-1" class="footnote">Foo</div>' +
          '</div>'
        )
      end
    end

    describe "LaTeX logo" do
      let(:polytex) { '\LaTeX' }
      it { should resemble('<span class="LaTeX"></span>') }
    end

    describe '\ldots' do
      let(:polytex) { '\ldots' }
      it { should resemble('&#133;') }
    end

    describe 'end-of-sentence punctuation' do
      let(:polytex) { 'Superman II\@. Lorem ipsum.' }
      it { should resemble('Superman II. Lorem ipsum.') }
    end

    describe 'unbreakable interword space' do
      let(:polytex) { 'foo~bar' }
      it { should resemble('foo&#160;bar') }
    end

    describe "verbatim environments" do
       let(:polytex) do <<-'EOS'
\begin{verbatim}
  \emph{foo bar}
\end{verbatim}
         EOS
       end

      let(:output) { '\emph{foo bar}' }

      it { should resemble(output) }
      it { should resemble('<pre class="verbatim">') }
      it { should_not resemble('\begin{verbatim}') }

      describe "with nesting" do
        let(:polytex) do <<-'EOS'
\begin{verbatim}
  \begin{verbatim}
  \emph{foo bar}
  \end{verbatim}
\end{verbatim}
         EOS
        end

        let(:output) do <<-'EOS'
  \begin{verbatim}
  \emph{foo bar}
  \end{verbatim}
         EOS
        end

        it { should resemble(output) }
      end

      describe 'with missing \end{verbatim}' do
        let(:polytex) do <<-'EOS'
\begin{verbatim}
  \emph{foo bar}
         EOS
        end

        it "should raise an error" do
          expect { subject }.to raise_error
        end
      end
    end
  end
end