# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  let(:pipeline) { Polytexnic::Pipeline.new(polytex) }
  subject(:processed_text) { pipeline.to_html }

  describe "aside boxes" do
    let(:polytex) do <<-'EOS'
      \chapter{Foo bar}

      \begin{aside}
      \heading{Lorem ipsum.}
      \label{aside:lorem}

      lorem ipsum

      dolor sit amet

      \end{aside}

      Box~\ref{aside:lorem}
      EOS
    end

    it do
      should resemble <<-'EOS'
        <div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cid1" class="heading"><span class="number">Chapter 1 </span>Foo bar</a></h1>
        <div class="aside" id="aside-lorem" data-tralics-id="uid1" data-number="1.1">
          <div class="heading">
            <span class="number">Box 1.1.</span>
            <span class="description">Lorem ipsum.</span>
          </div>
          <p>lorem ipsum</p>
          <p>dolor sit amet</p>
        </div>
        <p><a href="#aside-lorem" class="hyperref">Box <span class="ref">1.1</span></a></p>
        </div>
      EOS
    end

    context "with a custom language label" do
      before do
        pipeline.stub(:language_labels).
                 and_return({ "chapter" => { "word" => "Chapter",
                                             "order" => "standard" },
                              "aside" => "Cajón" })
      end
      it { should include 'Cajón 1.1' }
    end
  end

  describe "aside cross-references" do
    let(:aside) do <<-'EOS'
        \begin{aside}
        \heading{Lorem ipsum.}
        \label{aside:lorem}

        lorem ipsum

        dolor sit amet

        \end{aside}

        Box~\ref{aside:lorem}
      EOS
    end
    context "in a chapter" do
      let(:polytex) { '\chapter{Foo bar}' + "\n" + aside}
      it { should include ">1.1<" }
    end

    context "in an article" do
      let(:polytex) { '\section{A section}' + "\n" + aside }
      it { should include ">1<" }
    end
  end
end
