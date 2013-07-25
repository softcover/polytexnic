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
        <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo <em>bar</em></a></h3>
      </div>
      <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1">
        <h3><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h3>
        <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup></p>
      </div>
      <div id="cha-1_footnotes">
        <ol>
          <li id="cha-1_footnote-1">
            Cicero <a href="#cha-1_footnote-ref-1">↩</a>
          </li>
        </ol>
      </div>
      <div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2">
        <h3><a href="#cha-bar" class="heading"><span class="number">2 </span>Bar</a></h3>
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
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
        <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo <em>bar</em></a></h3>
      </div>
      <div id="sec-foobar" data-tralics-id="cid2" class="section" data-number="1.1">
        <h3><a href="#sec-foobar" class="heading"><span class="number">1.1 </span>Foobar</a></h3>
        <p>Lorem ipsum.<sup id="cha-1_footnote-ref-1" class="footnote"><a href="#cha-1_footnote-1">1</a></sup></p>
      </div>
      <div id="cha-1_footnotes">
        <ol>
          <li id="cha-1_footnote-1">
            Cicero <a href="#cha-1_footnote-ref-1">↩</a>
          </li>
        </ol>
      </div>
      <div id="cha-bar" data-tralics-id="cid3" class="chapter" data-number="2">
        <h3><a href="#cha-bar" class="heading"><span class="number">2 </span>Bar</a></h3>
        <p>Dolor sit amet.<sup id="cha-2_footnote-ref-1" class="footnote"><a href="#cha-2_footnote-1">1</a></sup></p>
      </div>
      <div id="cha-2_footnotes">
        <ol>
          <li id="cha-2_footnote-1">
            <em>Still</em> Cicero <a href="#cha-2_footnote-ref-1">↩</a>
          </li>
        </ol>
      </div>
      EOS
    end
    it { should resemble output }
  end
end