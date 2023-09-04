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

  describe "chapter theorems" do
    let(:polytex) do <<-'EOS'
      \chapter{Foo bar}

      \section{A section}
      \label{sec:the_section}

      \begin{theorem}
      \label{th:lorem}
      baz
      \end{theorem}

      \begin{lemma}
      \label{lemma:ipsum}
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

      We'll see another theorem in Theorem~\ref{th:another},
      and a lemma in Lemma~\ref{lemma:yet_another}.

      \chapter{Another chapter}

      We saw a theorem in Theorem~\ref{th:lorem} and a corollary
      in Corollary~\ref{cor:and_also}.

      \section{Another section}

      \begin{theorem}
      \label{th:another}
      Another theorem
      \end{end}

      \begin{lemma}
      \label{lemma:yet_another}
      Yet another lemma.
      \end{lemma}

      EOS
    end

    it { should include("lorem") }
    it { should include("Theorem 1.1") }
    it { should include("Lemma 1.2") }
    it { should include("Corollary 1.3") }
    it { should include("Definition 1.4") }
    it { should include("Remark 1.5") }
    it { should include("Theorem 2.1") }
    it { should include("Lemma 2.2") }
    it { should include('Theorem <a href="#th-lorem" class="hyperref"><span class="ref">1.1</span></a>')}
    it { should include('Theorem <a href="#th-another" class="hyperref"><span class="ref">2.1</span></a>')}
    it { should include('Lemma <a href="#lemma-yet_another" class="hyperref"><span class="ref">2.2</span></a>')}
  end

  describe "articles theorems" do
    before do
      pipeline.stub(:article?).and_return(true)
    end

    let(:polytex) do <<-'EOS'
      \section{A section}
      \label{sec:the_section}

      \begin{theorem}
      \label{th:lorem}
      baz
      \end{theorem}

      \begin{lemma}
      \label{lemma:ipsum}
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

      We'll see another theorem in Theorem~\ref{th:another},
      and a lemma in Lemma~\ref{lemma:yet_another}.

      We saw a theorem in Theorem~\ref{th:lorem} and a corollary
      in Corollary~\ref{cor:and_also}.

      \section{Another section}

      \begin{theorem}
      \label{th:another}
      Another theorem
      \end{end}

      \begin{lemma}
      \label{lemma:yet_another}
      Yet another lemma.
      \end{lemma}

      EOS
    end

    it { should include("lorem") }
    it { should include("Theorem 1") }
    it { should include("Lemma 2") }
    it { should include("Corollary 3") }
    it { should include("Definition 4") }
    it { should include("Remark 5") }
    it { should include("Theorem 6") }
    it { should include("Lemma 7") }
    it { should include('Theorem <a href="#th-lorem" class="hyperref"><span class="ref">1</span></a>')}
    it { should include('Theorem <a href="#th-another" class="hyperref"><span class="ref">6</span></a>')}
    it { should include('Lemma <a href="#lemma-yet_another" class="hyperref"><span class="ref">7</span></a>')}
  end

  # describe "theorem cross-references" do
  #   let(:theorems) do <<-'EOS'
  #     Let's prove (or at least state) a theorem!

  #     \begin{theorem}
  #     \label{th:lorem}
  #     baz
  #     \end{theorem}

  #     Oh, and also a lemma. This probably should have gone first.

  #     \begin{lemma}
  #     \label{lemma:ipsum}
  #     bar
  #     \end{lemma}

  #     Theorem~\ref{th:lorem} is a theorem. Lemma~\ref{lemma:ipsum} is---you
  #     guessed it!---a lemma.
  #     EOS
  #   end

  #   context "in a chapter" do
  #     let(:prematerial) { "\\chapter{Foo}\n\n\\section{Bar}" }
  #     let(:polytex) { prematerial + "\n" + theorems}
  #     it { should include('Theorem 1.1') }
  #     it { should include('Lemma 1.2') }
  #     it { should include('Theorem <a href="#th-lorem" class="hyperref"><span class="ref">1.1</span></a>')}
  #     it { should include('Lemma <a href="#lemma-ipsum" class="hyperref"><span class="ref">1.2</span></a>')}
  #   end

  #   context "in an article" do
  #     let(:polytex) { '\section{Test section}' + "\n" + theorems }
  #     it { should include('Theorem 1.1') }
  #     it { should include('Lemma 1.2') }
  #     it { should include('Theorem <a href="#th-lorem" class="hyperref"><span class="ref">1.1</span></a>')}
  #     it { should include('Lemma <a href="#lemma-ipsum" class="hyperref"><span class="ref">1.2</span></a>')}
  #   end
  # end
end
