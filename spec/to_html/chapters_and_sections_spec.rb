# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }

  describe '\chapter' do
    context "with a name" do
      let(:polytex) do <<-'EOS'
          \chapter{Foo \emph{bar}}
          \label{cha:foo}
        EOS
      end
      let(:output) do <<-'EOS'
        <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
          <h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
        </div>
        EOS
      end
      it { should resemble output }
    end

    context "with no name" do
      let(:polytex) do <<-'EOS'
          \chapter{}
          \label{cha:foo}
        EOS
      end
      let(:output) do <<-'EOS'
        <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
          <h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span></a></h1>
        </div>
        EOS
      end
      it { should resemble output }
    end

  end

  describe '\section' do
    let(:polytex) do <<-'EOS'
        \section{Foo}
        \label{sec:foo}
      EOS
    end
    let(:output) do <<-'EOS'
      <div id="sec-foo" data-tralics-id="cid1" class="section" data-number="1">
        <h2><a href="#sec-foo" class="heading"><span class="number">1 </span>Foo</a></h2>
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
        <h2><a href="#sec-foo" class="heading"><span class="number">1 </span>Foo</a></h2>
        <div id="sec-bar" data-tralics-id="uid1" class="subsection" data-number="1.1">
          <h3><a href="#sec-bar" class="heading"><span class="number">1.1 </span>Bar</a></h3>
        </div>
      </div>
      EOS
    end
    it { should resemble output }
  end

  describe '\subsubsection' do
    let(:polytex) do <<-'EOS'
        \chapter{The Chapter}
        \label{cha:the_chapter}

        \section{Foo}
        \label{sec:foo}

        \subsection{Bar}
        \label{sec:bar}

        \subsubsection{Baz}
        \label{sec:baz}
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-the_chapter" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cha-the_chapter" class="heading"><span class="number">Chapter 1 </span>The Chapter</a></h1>
       </div>
       <div id="sec-foo" data-tralics-id="cid2" class="section" data-number="1.1"><h2><a href="#sec-foo" class="heading"><span class="number">1.1 </span>Foo</a></h2>

       <div id="sec-bar" data-tralics-id="uid1" class="subsection" data-number="1.1.1"><h3><a href="#sec-bar" class="heading"><span class="number">1.1.1 </span>Bar</a></h3>

       <div id="sec-baz" data-tralics-id="uid2" class="subsubsection" data-number="1.1.1.1"><h4><a href="#sec-baz" class="heading">Baz</a></h4>
       </div>
       </div>
      </div>
      EOS
    end
    it { should resemble output }
  end

  describe '\chapter*' do
    let(:polytex) do <<-'EOS'
        \chapter*{Preface}
        Lorem ipsum
      EOS
    end
    it { should resemble '<div class="chapter-star">' }
  end

  describe '\section*, etc.' do
    let(:polytex) do <<-'EOS'
        \section*{Foo}

        \subsection*{Bar}

        Lorem ipsum

        \section{Baz}
      EOS
    end
    let(:output) do <<-'EOS'
      <div class="section-star">
        <h2><a class="heading">Foo</a></h2>
        <div class="subsection-star">
          <h3><a class="heading">Bar</a></h3>
          <p>Lorem ipsum</p>
        </div>
      </div>
      <div id="cid1" data-tralics-id="cid1" class="section" data-number="1">
        <h2><a href="#cid1" class="heading"><span class="number">1 </span>Baz</a></h2>
      </div>
      EOS
    end
    it { should resemble output }
  end

  describe 'chapter cross-references' do
    let(:polytex) do <<-'EOS'
        \chapter{Foo}
        \label{cha:foo_bar}

        Chapter~\ref{cha:foo_bar} and
        Chapter \ref{cha:foo_baz}

        \chapter{Baz}
        \label{cha:foo_baz}

        Chapter~\ref{cha:foo_baz} and
        Chapter \ref{cha:foo_bar}
      EOS
    end

    it do
      should resemble <<-'EOS'
        <div id="cha-foo_bar" data-tralics-id="cid1" class="chapter" data-number="1">
          <h1><a href="#cha-foo_bar" class="heading"><span class="number">Chapter 1 </span>Foo</a></h1>
          <p><a href="#cha-foo_bar" class="hyperref">Chapter <span class="ref">1</span></a>
          and
          <a href="#cha-foo_baz" class="hyperref">Chapter <span class="ref">2</span></a>
          </p>
        </div>

        <div id="cha-foo_baz" data-tralics-id="cid2" class="chapter" data-number="2">
          <h1><a href="#cha-foo_baz" class="heading"><span class="number">Chapter 2 </span>Baz</a></h1>
          <p><a href="#cha-foo_baz" class="hyperref">Chapter <span class="ref">2</span></a>
          and
          <a href="#cha-foo_bar" class="hyperref">Chapter <span class="ref">1</span></a>
          </p>
        </div>
      EOS
    end
  end

  describe "section cross-references" do
    let(:polytex) do <<-'EOS'
        \section{Foo}
        \label{sec:foo}

        Section~\ref{sec:bar} and Section~\ref{sec:baz}

        \subsection{Bar}
        \label{sec:bar}

        Section~\ref{sec:foo}

        \subsubsection{Baz}
        \label{sec:baz}
      EOS
    end

    it do
      should resemble <<-'EOS'
        <div id="sec-foo" data-tralics-id="cid1" class="section" data-number="1"><h2><a href="#sec-foo" class="heading"><span class="number">1 </span>Foo</a></h2>
        <p>
          <a href="#sec-bar" class="hyperref">Section <span class="ref">1.1</span></a>
          and
          <a href="#sec-baz" class="hyperref">Section <span class="ref">1.1.1</span></a>
        </p>
        <div id="sec-bar" data-tralics-id="uid1" class="subsection" data-number="1.1"><h3><a href="#sec-bar" class="heading"><span class="number">1.1 </span>Bar</a></h3>
        <p><a href="#sec-foo" class="hyperref">Section <span class="ref">1</span></a>
        </p>
        <div id="sec-baz" data-tralics-id="uid2" class="subsubsection" data-number="1.1.1">
          <h4><a href="#sec-baz" class="heading">Baz</a></h4>
        </div></div></div>
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
        <h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo</a></h1>
        <p><a href="#cha-bar" class="hyperref">Chapter <span class="undefined_ref">cha:bar</span></a>
        </p>
        </div>
      EOS
    end
  end

  describe "frontmatter and mainmatter" do
    let(:polytex) do <<-'EOS'
      \frontmatter
      \chapter{Foo}

      Lorem ipsum.\footnote{Foo bar.}

      \mainmatter
      \chapter{Bar}
      \label{cha:bar}

      Chapter~\ref{cha:bar}
      EOS
    end

    it do
      should resemble <<-'EOS'
<div id="frontmatter" data-number="0">
<div class="chapter-star"><h1><a class="heading">Foo</a></h1>
<p>Lorem ipsum.<sup id="cha-0_footnote-ref-1" class="footnote"><a href="#cha-0_footnote-1">1</a></sup></p>
</div></div>
<div id="cha-0_footnotes">
         <ol class="footnotes"><li id="cha-0_footnote-1">Foo bar. <a class="arrow" href="#cha-0_footnote-ref-1">↑</a></li>
         </ol></div>
<div id="cha-bar" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cha-bar" class="heading"><span class="number">Chapter 1 </span>Bar</a></h1>
<p><a href="#cha-bar" class="hyperref">Chapter <span class="ref">1</span></a>
</p></div>
      EOS
    end
  end
end