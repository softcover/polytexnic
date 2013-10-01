# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

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

  describe "Markdown footnotes" do
    subject do
      Polytexnic::Core::Pipeline.new(markdown, source: :markdown).polytex
    end

    describe "first chapter with footnotes" do
      let(:markdown) do <<-'EOS'
To add a footnote, you insert a footnote tag like this.[^foo]

Then you add the footnote content later in the text, using the same tag, with a colon and a space:[^foo2]

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
end