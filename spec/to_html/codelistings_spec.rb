# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  let(:pipeline) { Polytexnic::Pipeline.new(polytex) }
  subject(:processed_text) { pipeline.to_html }

  describe "code listings" do
    let(:polytex) do <<-'EOS'
\chapter{Foo bar}

\begin{codelisting}
\codecaption{Creating a \texttt{gem} configuration file. \\ \filepath{path/to/file}}
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
            <span class="number">Listing 1.1:</span>
            <span class="description">Creating a <code class="tt">gem</code> configuration file.<span class="intersentencespace"></span>
              <span class="break"></span>
              <code class="filepath">path/to/file</code>
            </span>
          </div>
          <div class="code">
            <div class="highlight">
              <pre><span></span><span class="gp">$</span> subl .gemrc</pre>
            </div>
          </div>
        </div>
        <p><a href="#code-create_gemrc" class="hyperref">Listing <span class="ref">1.1</span></a></p>
        </div>
      EOS
    end

    context "with a custom language label" do
      before do
        pipeline.stub(:language_labels).
                 and_return({ "chapter" => { "word" => "Chapter",
                                             "order" => "standard" },
                              "listing" => "Código" })
      end
      it { should include 'Código' }
    end


    context "with an empty caption" do
      let(:polytex) do <<-'EOS'
        \chapter{Foo bar}

        \begin{codelisting}
        \codecaption{}
        \label{code:create_gemrc}
        %= lang:console
        \begin{code}
  $ subl .gemrc
        \end{code}
        \end{codelisting}

        Listing~\ref{code:create_gemrc}
        EOS
      end
      it { should     include 'Listing 1.1' }
      it { should_not include 'Listing 1.1:' }
    end

    context "containing code inclusion with a hyphen and a leading dot" do
      let(:filename) { '.name-with-hyphens.txt' }
      before do
        File.write(File.join('spec', 'fixtures', filename), '')
      end
      after do
        FileUtils.rm(File.join('spec', 'fixtures', filename))
      end
      let(:polytex) do <<-'EOS'
  \begin{codelisting}
  \codecaption{Foo}
  \label{code:foo}
  %= <<(spec/fixtures/.name-with-hyphens.txt, lang: text)
  \end{codelisting}
        EOS
      end

      it "should not raise an error" do
        expect { processed_text }.not_to raise_error
      end
    end
  end

  describe "metacode listings" do
    let(:polytex) do <<-'EOS'
      \begin{codelisting}
      \label{code:listing}
      \codecaption{The heading.}
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
