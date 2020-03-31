# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

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
<div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
       </div>
       <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1"><h2><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h2>
       <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup></p>
       </div>
       <div id="cha-1_footnotes">
         <div class="footnotes">
           <div id="cha-1_footnote-1" class="footnote"><a class="footnote-link" href="#cha-1_footnote-ref-1">1.</a> Cicero</div>
         </div>
       </div><div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2"><h1><a href="#cha-bar" class="heading"><span class="number">Chapter 2 </span>Bar</a></h1>
       <p>Dolor sit amet.
       </p></div>
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
<div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
       </div>
       <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1"><h2><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h2>
       <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup></p>
       </div>
       <div id="cha-1_footnotes">
         <div class="footnotes">
           <div id="cha-1_footnote-1" class="footnote"><a class="footnote-link" href="#cha-1_footnote-ref-1">1.</a> Cicero</div>
         </div>
       </div><div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2"><h1><a href="#cha-bar" class="heading"><span class="number">Chapter 2 </span>Bar</a></h1>
       <p>Dolor sit amet.<sup id="cha-2_footnote-ref-1" class="footnote"><a href="#cha-2_footnote-1">1</a></sup></p>
       <p>Hey Jude.<sup id="cha-2_footnote-ref-2" class="footnote"><a href="#cha-2_footnote-2">2</a></sup>
       </p></div><div id="cha-2_footnotes">
         <div class="footnotes">
           <div id="cha-2_footnote-1" class="footnote"><a class="footnote-link" href="#cha-2_footnote-ref-1">1.</a> <em>Still</em> Cicero</div>
           <div id="cha-2_footnote-2" class="footnote"><a class="footnote-link" href="#cha-2_footnote-ref-2">2.</a> Lennon/McCartney</div>
         </div>
       </div>
      EOS
    end
    it { should resemble output }
  end

  describe "in a chapter title" do
    let(:polytex) { '\chapter{A chapter\protect\footnote{A footnote}}' }
    it { should include '</a><sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup>' }
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

        Dolor sit amet.\footnote{\emph{Still} Cicero.

        And Catullus.}

        Hey Jude!\footnote{Lennon/McCartney} Be afraid.
        \end{document}
      EOS
    end

    let(:output) do <<-'EOS'
<div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cha-foo" class="heading"><span class="number">Chapter 1 </span>Foo <em>bar</em></a></h1>
       </div>
       <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1"><h2><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h2>
       <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">*</a></sup></p>
       </div>
       <div id="cha-1_footnotes">
         <div class="footnotes nonumbers">
           <div id="cha-1_footnote-1" class="footnote"><sup><a class="footnote-link" href="#cha-1_footnote-ref-1">*</a></sup> Cicero</div>
         </div>
       </div><div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2"><h1><a href="#cha-bar" class="heading"><span class="number">Chapter 2 </span>Bar</a></h1>
       <p>Dolor sit amet.<sup id="cha-2_footnote-ref-1" class="footnote"><a href="#cha-2_footnote-1">*</a></sup></p>
       <p>Hey Jude!<sup id="cha-2_footnote-ref-2" class="footnote intersentence"><a href="#cha-2_footnote-2">†</a></sup><span class="intersentencespace"></span> Be afraid.<span class="intersentencespace"></span> </p></div>
       <div id="cha-2_footnotes">
         <div class="footnotes nonumbers">
           <div id="cha-2_footnote-1" class="footnote"><p><sup><a class="footnote-link" href="#cha-2_footnote-ref-1">*</a></sup> <em>Still</em> Cicero.</p>
       <p>And Catullus.</p>
       </div>
           <div id="cha-2_footnote-2" class="footnote"><sup><a class="footnote-link" href="#cha-2_footnote-ref-2">†</a></sup> Lennon/McCartney</div>
         </div>
       </div>
      EOS
    end
    it { should resemble output }
  end

  describe "emphasis inside footnote with a period" do
    let(:polytex) do <<-'EOS'
        \chapter{Lorem}
        Lorem ipsum\footnote{Dolor \emph{sit.}} amet. Consectetur.
      EOS
    end
    it { should_not include '</span> amet' }
  end

  describe "footnote inside a section*" do
    let(:polytex) do <<-'EOS'
        \chapter{The first}

        Test

        \chapter{The second}

        Also test

        \chapter{Lorem}

        Foo bar

        \section*{Baz}

        Lorem ipsum.\footnote{Dolor sit amet.}
      EOS
    end
    it { should include 'cha-3_footnote' }
  end
end
