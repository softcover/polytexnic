# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }

  describe "first chapter with footnotes" do
    let(:polytex) do <<-'EOS'
        \chapter{Foo \emph{bar}}
        \label{cha:foo}

        \section{Foobar}
        \label{sec:foobar}

        Lorem ipsum.\footnote{Cicero}

        \chapter{Bar}
        \label{cha:bar}

        Dolor sit amet.
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
        <h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
      </div>
      <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1">
        <h2><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h2>
        <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup></p>
      </div>
      <div id="cha-1_footnotes">
        <ol class="footnotes">
          <li id="cha-1_footnote-1">
            Cicero <a class="arrow" href="#cha-1_footnote-ref-1">↑</a>
          </li>
        </ol>
      </div>
      <div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2">
        <h1><a href="#cha-bar" class="heading"><span class="number">Chapter 2 </span>Bar</a></h1>
        <p>Dolor sit amet.</p>
      </div>
      EOS
    end
    it { should resemble output }
    it "should display the footnotes only once" do
      expect(processed_text.scan(/id="cha-1_footnotes"/).length).to eq 1
    end
  end

  describe "multiple chapters with footnotes" do
    let(:polytex) do <<-'EOS'
        \chapter{Foo \emph{bar}}
        \label{cha:foo}

        \section{Foobar}
        \label{sec:foobar}

        Lorem ipsum.\footnote{Cicero}

        \chapter{Bar}
        \label{cha:bar}

        Dolor sit amet.\footnote{\emph{Still} Cicero}

        Hey Jude.\footnote{Lennon/McCartney}
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
        <h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
      </div>
      <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1">
        <h2><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h2>
        <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup></p>
      </div>
      <div id="cha-1_footnotes">
        <ol class="footnotes">
          <li id="cha-1_footnote-1">
            Cicero <a class="arrow" href="#cha-1_footnote-ref-1">↑</a>
          </li>
        </ol>
      </div>
      <div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2">
        <h1><a href="#cha-bar" class="heading"><span class="number">Chapter 2 </span>Bar</a></h1>
        <p>Dolor sit amet.<sup id="cha-2_footnote-ref-1" class="footnote"><a href="#cha-2_footnote-1">1</a></sup></p>
        <p>Hey Jude.<sup id="cha-2_footnote-ref-2" class="footnote"><a href="#cha-2_footnote-2">2</a></sup></p>
      </div>
      <div id="cha-2_footnotes">
        <ol class="footnotes">
          <li id="cha-2_footnote-1">
            <em>Still</em> Cicero <a class="arrow" href="#cha-2_footnote-ref-1">↑</a>
          </li>
          <li id="cha-2_footnote-2">
            Lennon/McCartney <a class="arrow" href="#cha-2_footnote-ref-2">↑</a>
          </li>
        </ol>
      </div>
      EOS
    end
    it { should resemble output }
  end

  describe "symbols in place of numbers" do
    let(:polytex) do <<-'EOS'
        \documentclass{book}
        \renewcommand{\thefootnote}{\fnsymbol{footnote}}
        \begin{document}
        \chapter{Foo \emph{bar}}
        \label{cha:foo}

        \section{Foobar}
        \label{sec:foobar}

        Lorem ipsum.\footnote{Cicero}

        \chapter{Bar}
        \label{cha:bar}

        Dolor sit amet.\footnote{\emph{Still} Cicero}

        Hey Jude!\footnote{Lennon/McCartney} Be afraid.
        \end{document}
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
        <h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
      </div>
      <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1">
        <h2><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h2>
        <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">*</a></sup></p>
      </div>
      <div id="cha-1_footnotes">
        <ul class="footnotes nonumbers">
          <li id="cha-1_footnote-1">
            <sup>*</sup> Cicero <a class="arrow" href="#cha-1_footnote-ref-1">↑</a>
          </li>
        </ul>
      </div>
      <div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2">
        <h1><a href="#cha-bar" class="heading"><span class="number">Chapter 2 </span>Bar</a></h1>
        <p>Dolor sit amet.<sup id="cha-2_footnote-ref-1" class="footnote"><a href="#cha-2_footnote-1">*</a></sup></p>
        <p>Hey Jude!<sup id="cha-2_footnote-ref-2" class="footnote intersentence"><a href="#cha-2_footnote-2">†</a></sup><span class="intersentencespace"></span>
        Be afraid.<span class="intersentencespace"></span></p>
      </div>
      <div id="cha-2_footnotes">
        <ul class="footnotes nonumbers">
          <li id="cha-2_footnote-1">
            <sup>*</sup> <em>Still</em> Cicero <a class="arrow" href="#cha-2_footnote-ref-1">↑</a>
          </li>
          <li id="cha-2_footnote-2">
            <sup>†</sup> Lennon/McCartney <a class="arrow" href="#cha-2_footnote-ref-2">↑</a>
          </li>
        </ul>
      </div>
      EOS
    end
    it { should resemble output }
  end
end