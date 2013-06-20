# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "code listings" do
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
        <div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h3><a href="#cid1" class="heading"><span class="number">1 </span>Foo bar</a></h3>
        <div id="aside-lorem" data-tralics-id="uid1" class="aside" data-number="1.1">
          <div class="aside">
            <span class="header">Listing 1.1.</span>
            <span class="description">Creating a gem configuration file.</span>
          </div>
          <p>lorem ipsum</p>
          <p>dolor sit amet</p>
        </div>
        <p><a href="#code-create_gemrc" class="hyperref">Listing <span class="ref">1.1</span></a></p>
        </div>
      EOS
    end
  end
end