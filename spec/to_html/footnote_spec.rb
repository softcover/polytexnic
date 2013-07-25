# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "multiple chapters with footnotes" do
    let(:polytex) do <<-'EOS'
        \chapter{Foo \emph{bar}}
        \label{cha:foo}

        Lorem ipsum.\footnote{Cicero}

        \chapter{Bar}
        \label{cha:bar}

        Dolor sit amet.\footnote{\emph{Still} Cicero}
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
        <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo <em>bar</em></a></h3>
        <p>Lorem ipsum.<sup id="cha-foo_footnote-ref-1" class="footnote"><a href="#cha-foo_footnote-1">1</a></sup></p>
        <div id="cha-foo_footnotes">
          <ol>
            <li id="cha-foo_footnote-1">
              Cicero <a href="#cha-foo_footnote-ref-1">↩</a>
            </li>
          </ol>
        </div>
      </div>
        <div id="cha-bar" data-tralics-id="cid2" class="chapter" data-number="2">
        <h3><a href="#cha-bar" class="heading"><span class="number">2 </span>Bar</a></h3>
        <p>Dolor sit amet.<sup id="cha-bar_footnote-ref-1" class="footnote"><a href="#cha-bar_footnote-1">1</a></sup></p>
        <div id="cha-bar_footnotes">
          <ol>
            <li id="cha-bar_footnote-1">
              <em>Still</em> Cicero <a href="#cha-bar_footnote-ref-1">↩</a>
            </li>
          </ol>
        </div>
      </div>
      EOS
    end
    it { should resemble output }
  end
end