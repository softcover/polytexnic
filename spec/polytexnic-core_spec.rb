# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do


  describe '#to_latex' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_latex }
    subject { processed_text }

    describe "for vanilla LaTeX" do
      let(:polytex) { '\emph{foo}' }
      it { should include(polytex) }
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

      it { should resemble "commandchars=\\\\\\{" }
      it { should resemble '\begin{Verbatim}' }
      it { should resemble 'commandchars' }
      it { should resemble '\end{Verbatim}' }
      it { should_not resemble 'def foo' }
      it { should resemble '\noindent lorem ipsum' }

      describe "in the middle of a line" do
        let(:polytex) { 'Use \verb+%= lang:ruby+ to highlight Ruby code' }
        it { should resemble '\verb' }
        it { should_not resemble '<div class="highlight">' }
      end
    end

    context "with the metacode environment" do
      let(:polytex) do <<-'EOS'
%= lang:latex
\begin{metacode}
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}
\end{metacode}

\noindent lorem ipsum
        EOS
      end

      it { should resemble "commandchars=\\\\\\{" }
      it { should_not resemble '%= lang:ruby' }
    end

    describe "verbatim environments" do
      let(:polytex) do <<-'EOS'
\begin{verbatim}
def foo
  "bar"
end
\end{verbatim}

\begin{Verbatim}
def foo
  "bar"
end
\end{Verbatim}
      EOS
      end

      it { should resemble polytex }

      context "containing an example of highlighted code" do
        let(:polytex) do <<-'EOS'
\begin{verbatim}
%= lang:ruby
def foo
  "bar"
end
\end{verbatim}
          EOS
        end

        it { should resemble polytex }
      end
    end

    describe "hyperref links" do
      let(:polytex) do <<-'EOS'
Chapter~\ref{cha:foo}
      EOS
      end
      let(:output) { '\hyperref[cha:foo]{Chapter~\ref{cha:foo}' }
      it { should resemble output }
    end
  end

  describe '#to_html' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
    subject { processed_text }

    describe "Unicode" do
      let(:first) { 'Алексей' }
      let(:last) { 'Разуваев' }
      let(:polytex) { "#{first} #{last}" }
      let(:output) { polytex }
      it { should include(first) }
      it { should include(last) }
    end

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

      it { should resemble "<p>lorem ipsum</p>" }
    end

    describe "paragraph conversion" do
      let(:polytex) { 'lorem ipsum' }
      it { should resemble "<p>lorem ipsum</p>" }
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

    describe "boldface" do
      let(:polytex) { '\textbf{boldface}' }
      it { should resemble '<strong>boldface</strong>' }
    end

    describe "small caps" do
      let(:polytex) { '\textsc{small caps}' }
      it { should resemble '<span class="sc">small caps</span>' }
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

      context "with single quotes" do
        let(:polytex) { "`foo bar'" }
        it { should resemble '‘foo bar’' }
      end

      context "with an apostrophe" do
        let(:polytex) { "don't stop believin'" }
        it { should resemble 'don’t stop believin’' }
      end
    end

    describe "quote" do
      let(:polytex) { '\quote{foo}' }
      it { should resemble "<blockquote class=\"quote\">foo\n</blockquote>" }
    end

    describe "quote environment" do
      let(:polytex) do <<-'EOS'
\begin{quote}
  lorem ipsum

  dolor sit amet
\end{quote}
        EOS
      end
      it do
        should resemble <<-'EOS'
<blockquote>
  <p>lorem ipsum</p>
  <p>dolor sit amet</p>
</blockquote>
        EOS
      end

      context "when nested" do
        let(:polytex) do <<-'EOS'
\begin{quote}
  lorem ipsum

  \begin{quote}
    foo bar
  \end{quote}

  dolor sit amet
\end{quote}
          EOS
        end
        it do
          should resemble <<-'EOS'
<blockquote>
  <p>lorem ipsum</p>
  <blockquote>
  <p>foo bar</p>
  </blockquote>
  <p>dolor sit amet</p>
</blockquote>
          EOS
        end
      end
    end

    describe "verse" do
      let(:polytex) { '\verse{foo}' }
      it { should resemble "<blockquote class=\"verse\">foo\n</blockquote>" }
    end

    describe "verse environment" do
      let(:polytex) do <<-'EOS'
\begin{verse}
  lorem ipsum\\
  dolor sit amet
\end{verse}
        EOS
      end
      it do
        should resemble <<-'EOS'
<blockquote class="verse">
  <p>lorem ipsum</p>
  <p class="noindent">dolor sit amet</p>
</blockquote>
        EOS
      end
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

    describe "itemized list" do
      let(:polytex) do <<-'EOS'
\begin{itemize}
  \item Foo
  \item Bar
\end{itemize}
        EOS
      end
      it do
        should resemble <<-'EOS'
<ul>
  <li>Foo</li>
  <li>Bar</li>
</ul>
        EOS
      end

      context "preceded by text" do
        let(:polytex) do <<-'EOS'
lorem ipsum

\begin{itemize}
  \item Foo
  \item Bar
\end{itemize}
          EOS
        end
        it do
          should resemble <<-'EOS'
<p>lorem ipsum</p>
<ul>
  <li>Foo</li>
  <li>Bar</li>
</ul>
         EOS
        end
      end
      context "itemized list followed by text" do
        let(:polytex) do <<-'EOS'
\begin{itemize}
  \item Foo
  \item Bar
\end{itemize}

lorem ipsum
          EOS
        end
        it do
         should resemble <<-'EOS'
<ul>
  <li>Foo</li>
  <li>Bar</li>
</ul><p>lorem ipsum
</p>
          EOS
        end
      end
    end

    describe "enumerated list" do
      let(:polytex) do <<-'EOS'
\begin{enumerate}
  \item Foo
  \item Bar
\end{enumerate}
        EOS
      end
      it do
        should resemble <<-'EOS'
<ol>
  <li>Foo</li>
  <li>Bar</li>
</ol>
        EOS
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
          <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo</a></h3>
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
        <div id="sec-foo" data-tralics-id="cid1" class="section" data-number="1">
          <h3><a href="#sec-foo" class="heading"><span class="number">1 </span>Foo</a></h3>
        </div>
        EOS
      end
      it { should resemble output }
    end

    describe '\subsection' do
      let(:polytex) do <<-'EOS'
          \section{Foo}
          \label{sec:foo}

          \subsection{Bar}
          \label{sec:bar}
        EOS
      end

      let(:output) do <<-'EOS'
        <div id="sec-foo" data-tralics-id="cid1" class="section" data-number="1">
          <h3><a href="#sec-foo" class="heading"><span class="number">1 </span>Foo</a></h3>
          <div id="sec-bar" data-tralics-id="uid1" class="subsection" data-number="1.1">
            <h4><a href="#sec-bar" class="heading"><span class="number">1.1 </span>Bar</a></h4>
          </div>
        </div>
        EOS
      end
      it { should resemble output }
    end

    describe 'cross-references with \ref' do
      let(:polytex) do <<-'EOS'
          \chapter{Foo}
          \label{cha:foo}

          bar Chapter~\ref{cha:foo}
          Chapter \ref{cha:foo}
        EOS
      end

      it do
        should resemble <<-'EOS'
<div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
  <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo</a></h3>
  <p>bar <a href="#cha-foo" class="hyperref">Chapter <span class="ref">1</span></a>
  <a href="#cha-foo" class="hyperref">Chapter <span class="ref">1</span></a>
  </p>
</div>
        EOS
      end
    end

    describe 'missing cross-references' do
      let(:polytex) do <<-'EOS'
\chapter{Foo}
\label{cha:foo}

Chapter~\ref{cha:bar}
        EOS
      end

      it do
        should resemble <<-'EOS'
<div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
  <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo</a></h3>
  <p><a href="#cha-bar" class="hyperref">Chapter <span class="undefined_ref">cha:bar</span></a>
  </p>
</div>
      EOS
      end
    end

    describe "(La)TeX logos" do

      describe "TeX logo" do
        let(:polytex) { '\TeX' }
        let(:output) do
%(<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>)
        end
        it { should include(output) }
      end

      describe "LaTeX logo" do
        let(:polytex) { '\LaTeX' }
        let(:output) do
%(<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">L<span style="text-transform: uppercase; font-size: 70%; margin-left: -0.36em; vertical-align: 0.3em; line-height: 0; margin-right: -0.15em;">A</span>T<span style="text-transform: uppercase; margin-left: -0.1667em; vertical-align: -0.5ex; line-height: 0; margin-right: -0.125em;">E</span>X</span>)
        end
        it { should include(output) }
      end

      describe "PolyTeX logo" do
        let(:polytex) { '\PolyTeX' }
        let(:output) do
%(Poly<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>)
        end
        it { should include(output) }
      end

      describe "PolyTeXnic logo" do
        let(:polytex) { '\PolyTeXnic' }
        let(:output) do
%(Poly<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>nic)
        end
        it { should include(output) }
      end
    end

    describe "unknown command" do
      let(:polytex) { '\foobar' }
      let(:output) { '' }
      it { should resemble output }
    end

    describe "href" do
      let(:polytex) { '\href{http://example.com/}{Example Site}' }
      let(:output) { '<a href="http://example.com/">Example Site</a>' }
      it { should resemble output }
    end

    describe "graphics" do
      let(:polytex) do <<-'EOS'
\includegraphics{foo.png}
        EOS
      end

      it do
        should resemble <<-'EOS'
<div class="graphics">
  <img src="foo.png" alt="foo" />
</div>
        EOS
      end
    end

    describe "figures" do
      let(:polytex) do <<-'EOS'
\begin{figure}
lorem
\end{figure}
        EOS
      end

      it do
        should resemble <<-'EOS'
<div id="uid1" data-tralics-id="uid1" data-number="1" class="figure">
  <p>lorem</p>
  <div class="caption">
    <span class="header">Figure 1</span>
  </div>
</div>
        EOS
      end

      context "with a label and a cross-reference" do
        let(:polytex) do <<-'EOS'
\begin{figure}
lorem
\label{fig:foo}
\end{figure}

Figure~\ref{fig:foo}
          EOS
        end

        it do
          should resemble <<-'EOS'
<div id="fig-foo" data-tralics-id="uid1" data-number="1" class="figure">
  <p>lorem</p>
  <div class="caption">
    <span class="header">Figure 1</span>
  </div>
</div>
<p><a href="#fig-foo" class="hyperref">Figure <span class="ref">1</span></a></p>
          EOS
        end
      end

      context "with included graphics" do
        let(:polytex) do <<-'EOS'
\begin{figure}
\includegraphics{images/foo.png}
\end{figure}
          EOS
        end

        it do
          should resemble <<-'EOS'
<div id="uid1" data-tralics-id="uid1" data-number="1" class="figure">
  <div class="graphics">
    <img src="images/foo.png" alt="foo" />
  </div>
  <div class="caption">
    <span class="header">Figure 1</span>
  </div>
</div>
          EOS
        end
      end

      context "with a caption" do
        let(:polytex) do <<-'EOS'
\chapter{The chapter}

\begin{figure}
\includegraphics{foo.png}
\caption{This is a caption.}
\end{figure}

\begin{figure}
\includegraphics{bar.png}
\caption{This is another caption.}
\end{figure}
           EOS
         end

         it do
           should resemble <<-'EOS'
<div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1">
  <h3>
    <a href="#cid1" class="heading">
    <span class="number">1 </span>The chapter</a>
  </h3>
  <div id="uid1" data-tralics-id="uid1" data-number="1.1" class="figure">
    <div class="graphics">
      <img src="foo.png" alt="foo" />
    </div>
    <div class="caption">
      <span class="header">Figure 1.1: </span>
      <span class="description">This is a caption.</span>
    </div>
  </div>
  <div id="uid2" data-tralics-id="uid2" data-number="1.2" class="figure">
    <div class="graphics">
      <img src="bar.png" alt="bar" />
    </div>
    <div class="caption">
      <span class="header">Figure 1.2: </span>
      <span class="description">This is another caption.</span>
    </div>
  </div>
</div>
          EOS
        end
      end

      context "with labels and cross-reference" do
        let(:polytex) do <<-'EOS'
 \chapter{The chapter}
 \label{cha:lorem_ipsum}

 \begin{figure}
 \includegraphics{foo.png}
 \caption{This is a caption.\label{fig:foo}}
 \end{figure}

\begin{figure}
\includegraphics{bar.png}
\caption{This is another caption.\label{fig:bar}}
\end{figure}


 Figure~\ref{fig:foo} and Figure~\ref{fig:bar}
           EOS
         end

         it do
           should resemble <<-'EOS'
<div id="cha-lorem_ipsum" data-tralics-id="cid1" class="chapter" data-number="1">
  <h3>
    <a href="#cha-lorem_ipsum" class="heading">
    <span class="number">1 </span>The chapter</a>
  </h3>
  <div id="fig-foo" data-tralics-id="uid1" data-number="1.1" class="figure">
    <div class="graphics">
      <img src="foo.png" alt="foo" />
    </div>
    <div class="caption">
      <span class="header">Figure 1.1: </span>
      <span class="description">This is a caption.</span>
    </div>
  </div>
  <div id="fig-bar" data-tralics-id="uid2" data-number="1.2" class="figure">
    <div class="graphics">
      <img src="bar.png" alt="bar" />
    </div>
    <div class="caption">
      <span class="header">Figure 1.2: </span>
      <span class="description">This is another caption.</span>
    </div>
  </div>
  <p>
    <a href="#fig-foo" class="hyperref">Figure <span class="ref">1.1</span></a>
    and
    <a href="#fig-bar" class="hyperref">Figure <span class="ref">1.2</span></a>
  </p>
</div>
          EOS
        end
      end
    end
  end
end