# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  let(:pipeline) { Polytexnic::Pipeline.new(polytex) }
  subject(:processed_text) { pipeline.to_html }

  describe "proof" do
    let(:polytex) do <<-'EOS'
      \chapter{Foo bar}

      \begin{proof}
      Lorem ipsum.
      \end{proof}
      EOS
    end
    it { should include("Lorem ipsum.") }
    it { should include('<div class="proof">')}
  end

  describe "theorems" do
    let(:polytex) do <<-'EOS'
      \chapter{Foo bar}

      \section{A section}

      \begin{theorem}
      \label{th:lorem}
      baz
      \end{theorem}

      \begin{lemma}
      bar
      \end{lemma}

      \begin{corollary}
      \label{cor:and_also}
      quux
      \end{corollary}

      \begin{definition}
      \label{def:a_definition}
      foo
      \end{definition}

      \begin{remark}
      able
      \end{remark}

      Theorem~\ref{th:lorem}
      EOS
    end

    it { should include("lorem") }

    it { should include("Theorem 1.1") }
    it { should include("Lemma 1.2") }
    it { should include("Corollary 1.3") }
    it { should include("Definition 1.4") }
    it { should include("Remark 1.5") }


  #   context "with a custom language label" do
  #     before do
  #       pipeline.stub(:language_labels).
  #                and_return({ "chapter" => { "word" => "Chapter",
  #                                            "order" => "standard" },
  #                             "aside" => "Cajón" })
  #     end
  #     it { should include 'Cajón 1.1' }
  #   end
  # end

  # describe "aside cross-references" do
  #   let(:aside) do <<-'EOS'
  #       \begin{aside}
  #       \heading{Lorem ipsum.}
  #       \label{aside:lorem}

  #       lorem ipsum

  #       dolor sit amet

  #       \end{aside}

  #       Box~\ref{aside:lorem}
  #     EOS
  #   end
  #   context "in a chapter" do
  #     let(:polytex) { '\chapter{Foo bar}' + "\n" + aside}
  #     it { should include ">1.1<" }
  #   end

  #   context "in an article" do
  #     let(:polytex) { '\section{A section}' + "\n" + aside }
  #     it { should include ">1<" }
  #   end
  end
end
