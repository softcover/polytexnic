# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "code listings" do
    let(:polytex) do <<-'EOS'
      \chapter{Foo bar}

      \begin{codelisting}
      Creating a gem configuration file.
      \label{code:create_gemrc}
      %= lang:console
      \begin{code}
$ subl .gemrc
      \end{code}
      \end{codelisting}

      Listing~\ref{code:create_gemrc}
      EOS
    end

    it do
      should resemble <<-'EOS'
        <div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h3><a href="#cid1" class="heading"><span class="number">1 </span>Foo bar</a></h3>
        <div id="code-create_gemrc" data-tralics-id="uid1" class="codelisting" data-number="1.1">
          <div class="listing">
            <span class="header">Listing 1.1.</span>
            <span class="description">Creating a gem configuration file.</span>
          </div>
          <div class="code">
            <div class="highlight">
              <pre><span class="gp">$</span> subl .gemrc</pre>
            </div>
          </div>
        </div>
        <p><a href="#code-create_gemrc" class="hyperref">Listing <span class="ref">1.1</span></a></p>
        </div>
      EOS
    end
  end
end