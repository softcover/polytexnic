# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }


  describe "bare footnote command" do
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

  describe "multiple chapters with footnotes" do
    let(:polytex) do <<-'EOS'
        \chapter{Foo \emph{bar}}
        \label{cha:foo}

        Lorem ipsum.\footnote{Cicero}

        \chapter{Bar}
        \label{cha:bar}

        Dolor sit amet.\footnote{Still Cicero}
      EOS
    end

    let(:output) do <<-'EOS'
      <div id="cha-foo" data-tralics-id="cid1" class="chapter" data-number="1">
        <h3><a href="#cha-foo" class="heading"><span class="number">1 </span>Foo <em>bar</em></a></h3>
        <p>Lorem ipsum.<sup class="footnote"><a href="#footnote-1">1</a></sup></p>
        <div id="cid1-footnotes">
          <ol>
            <li id="cid1-footnote-1">Cicero</li>
          </ol>
        </div>
      </div>
        <div id="cha-bar" data-tralics-id="cid2" class="chapter" data-number="2">
        <h3><a href="#cha-bar" class="heading"><span class="number">2 </span>Bar</a></h3>
        <p>Dolor sit amet.<sup class="footnote"><a href="#footnote-1">1</a></sup></p>
        <div id="cid2-footnotes">
          <ol>
            <li id="cid2-footnote-1">Still Cicero</li>
          </ol>
        </div>
      </div>
      EOS
    end
    it { should resemble output }
  end
end