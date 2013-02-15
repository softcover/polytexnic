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
        it { should =~ /“foo bar”/ }
      end
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
      it { should resemble('<span class="verbatim">') }
    end
  end
end