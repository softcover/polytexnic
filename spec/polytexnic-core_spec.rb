# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do

  describe '#to_latex' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_latex }
    subject { processed_text }

    describe "for vanilla LaTeX" do
      let(:polytex) { '\emph{foo}' }
      it { should eql(polytex) }
    end

    describe "with source code highlighting" do
      let(:polytex) do <<-'EOS'
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}

\noindent lorem ipsum
      EOS
      end

      it { should resemble '\begin{Verbatim}' }
      it { should resemble 'commandchars' }
      it { should resemble '\end{Verbatim}' }
      it { should_not resemble 'def foo' }
      it { should resemble '\noindent lorem ipsum' }
    end

    describe "Unicode" do
      let(:polytex) { 'Алексей Разуваев' }
      let(:output) { polytex }
      it { should include(output) }
    end
  end

  describe '#to_html' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
    subject { processed_text }

    describe "comments" do
      let(:polytex) { "% A LaTeX comment" }
      it { should resemble "" }
    end

    describe "a complete document" do
      let(:polytex) do <<-'EOS'
\documentclass{book}

\begin{document}
lorem ipsum
\end{document}
        EOS
      end

      it { should resemble "<p>lorem ipsum\n</p>" }
    end

    describe "paragraph conversion" do
      let(:polytex) { 'lorem ipsum' }
      it { should resemble "<p>lorem ipsum\n</p>" }
      it { should_not resemble '<unknown>' }
    end

    describe "italics conversion" do
      let(:polytex) { '\emph{foo bar}' }
      it { should resemble '<em>foo bar</em>' }
    end

    describe "italics with multiple instances" do
      let(:polytex) do
        '\emph{foo bar} and also \emph{baz quux}'
      end

      it { should resemble '<em>foo bar</em>' }
      it { should resemble '<em>baz quux</em>' }
    end

    describe "typewriter text" do
      let(:polytex) { '\texttt{typewriter text}' }
      it { should resemble '<span class="tt">typewriter text</span>' }
    end

    describe "quoted strings" do
      context "with single quotes" do
        let(:polytex) { "``foo bar''" }
        it { should resemble '“foo bar”' }
      end
    end

    describe "quote" do
      let(:polytex) { '\quote{foo}' }
      it { should resemble "<blockquote class=\"quote\">foo\n</blockquote>" }
    end

    describe "verse" do
      let(:polytex) { '\verse{foo}' }
      it { should resemble "<blockquote class=\"verse\">foo\n</blockquote>" }
    end

    describe "itemize" do
      let(:polytex) { '\itemize' }
      it { should resemble '<ul></ul>'}
    end

    describe "enumerate" do
      let(:polytex) { '\enumerate' }
      it { should resemble '<ol></ol>'}
    end

    describe "item" do
      let(:polytex) { '\item foo' }
      it { should resemble "<li>foo\n</li>"}
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

    describe '\ldots' do
      let(:polytex) { '\ldots' }
      it { should resemble '…' }
    end

    describe 'end-of-sentence punctuation' do
      let(:polytex) { 'Superman II\@. Lorem ipsum.' }
      it { should resemble 'Superman II. Lorem ipsum.' }
    end

    describe 'unbreakable interword space' do
      let(:polytex) { 'foo~bar' }
      it { should resemble 'foo bar' }
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
      let(:polytex) do <<-'EOS'
          \chapter{Foo}
          \label{cha:foo}
        EOS
      end
      let(:output) do <<-'EOS'
        <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
          <h3><a href="#cha-foo" class="heading"><span class="number">1</span>Foo</a></h3>
        </div>
        EOS
      end
      it { should resemble output }
    end

    describe '\section' do
      let(:polytex) do <<-'EOS'
          \section{Foo}
          \label{sec:foo}
        EOS
      end
      let(:output) do <<-'EOS'
        <div id="sec-foo" data-tralics-id="cid1" class="section" data-number="1.1">
          <h3><a href="#sec-foo" class="heading"><span class="number">1.1</span>Foo</a></h3>
        </div>
        EOS
      end
      it { should resemble output }
    end

    describe '\subsection' do
      let(:polytex) do <<-'EOS'
          \subsection{Foo}
          \label{subsec:foo}
        EOS
      end

      let(:output) do <<-'EOS'
        <div id="subsec-foo" data-tralics-id="uid1" class="subsection" data-number="1.1.1">
          <h4><a href="#subsec-foo" class="heading">Foo</a></h4>
        </div>
        EOS
      end
      it { should resemble output }
    end

    describe '\ref and \hyperref' do
      let(:polytex) do <<-'EOS'
          \chapter{Foo}
          \label{cha:foo}
          \hyperref[cha:foo]{Foo~\ref{cha:foo}}

          bar
        EOS
      end

      it do
        should resemble <<-'EOS'
<div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
  <h3><a href="#cha-foo" class="heading"><span class="number">1</span>Foo</a></h3>
  <p><a href="#cha-foo" class="hyperref">Foo <span class="ref">1</span></a></p>
  <p>bar
  </p>
</div>
        EOS
      end
    end

    describe "(La)TeX logos" do

      describe "TeX logo" do
        let(:polytex) { '\TeX' }
        let(:output) { '\( \mathrm{\TeX} \)' }
        it { should include(output) }
      end

      describe "LaTeX logo" do
        let(:polytex) { '\LaTeX' }
        let(:output) { '\( \mathrm{\LaTeX} \)' }
        it { should include(output) }
      end
    end
  end
end