# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  describe '#to_html' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
    subject { processed_text }

    describe "paragraph conversion" do
      let(:polytex) { 'lorem ipsum' }
      it { should resemble("<p>lorem ipsum\n</p>") }
      it { should_not resemble('<unknown>') }
    end

    describe "italics conversion" do
      let(:polytex) { '\emph{foo bar}' }
      it { should resemble('<em>foo bar</em>') }
    end

    describe "italics with multiple instances" do
      let(:polytex) do
        '\emph{foo bar} and also \emph{baz quux}'
      end

      it { should resemble('<em>foo bar</em>') }
      it { should resemble('<em>baz quux</em>') }
    end

    describe "quoted strings" do
      context "with single quotes" do
        let(:polytex) { "``foo bar''" }
        it { should resemble('“foo bar”') }
      end
    end

    describe "footnotes" do
      let(:polytex) { '\footnote{Foo}' }
      it do
        should resemble('<sup class="footnote">' +
                          '<a href="#footnote-1">1</a>' +
                        '</sup>')
      end
      it do
        out = '<div id="footnotes"><ol><li id="footnote-1">Foo</li></ol></div>'
        should resemble out
      end
    end

    describe "LaTeX logo" do
      let(:polytex) { '\LaTeX' }
      it { should resemble('<span class="LaTeX"></span>') }
    end

    describe '\ldots' do
      let(:polytex) { '\ldots' }
      it { should resemble('…') }
    end

    describe 'end-of-sentence punctuation' do
      let(:polytex) { 'Superman II\@. Lorem ipsum.' }
      it { should resemble('Superman II. Lorem ipsum.') }
    end

    describe 'unbreakable interword space' do
      let(:polytex) { 'foo~bar' }
      it { should resemble('foo bar') }
    end

    describe '\maketitle' do
      let(:polytex) do <<-'EOS'
          \title{Foo}
          \subtitle{Bar}
          \author{Leslie Lamport}
          \date{Jan 1, 1971}
          \begin{document}
            \maketitle
          \end{document}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <h1 class="title">Foo</h1>
          <h1 class="subtitle">Bar</h1>
          <h2 class="author">Leslie Lamport</h2>
          <h2 class="date">Jan 1, 1971</h2>
        EOS
      end
    end

    describe '\chapter' do
      let(:polytex) { '\chapter{Foo Bar}' }
      let(:output) do <<-'EOS'
        <h1 class="chapter">
          <a id="sec-1"></a><span>Foo Bar</span>
        </h1>
        EOS
      end
      it { should resemble(output) }
    end
  end
end