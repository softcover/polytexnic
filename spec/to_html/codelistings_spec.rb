# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }

  describe "code listings" do
    let(:polytex) do <<-'EOS'
      \chapter{Foo bar}

      \begin{codelisting}
      \heading{Creating a \texttt{gem} configuration file. \\ filename}
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
        <div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cid1" class="heading"><span class="number">Chapter 1 </span>Foo bar</a></h1>
        <div class="codelisting" id="code-create_gemrc" data-tralics-id="uid1" data-number="1.1">
          <div class="heading">
            <span class="number">Listing 1.1.</span>
            <span class="description">Creating a <span class="tt">gem</span> configuration file. <span class="break"></span> filename</span>
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

  describe "metacode listings" do
    let(:polytex) do <<-'EOS'
      \begin{codelisting}
      \heading{The heading.}
      \label{code:listing}
      %= lang:latex
      \begin{metacode}
      %= lang:ruby
      \begin{code}
      def foo
        "bar"
      end
      \end{code}
      \end{metacode}
      \end{codelisting}
      EOS
    end

    it "should not raise an error" do
      expect { processed_text }.not_to raise_error
    end
  end
end