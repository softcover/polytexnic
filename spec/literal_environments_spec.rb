# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).process }
  subject { processed_text }

    describe "verbatim environments" do
      let(:polytex) do <<-'EOS'
\begin{verbatim}
\emph{foo bar}
\end{verbatim}
        EOS
      end

    let(:output) { '\emph{foo bar}' }

    it { should resemble(output) }
    it { should resemble('<pre class="verbatim">') }
    it { should_not resemble('\begin{verbatim}') }

    describe "with nesting" do
      let(:polytex) do <<-'EOS'
\begin{verbatim}
\begin{verbatim}
\emph{foo bar}
\end{verbatim}
\end{verbatim}
lorem ipsum
       EOS
      end

      let(:output) do <<-'EOS'
\begin{verbatim}
\emph{foo bar}
\end{verbatim}
       EOS
      end

      it { should resemble(output) }
      it "should break out of the loop if verbatim count is zero" do
        expect(processed_text).to resemble('lorem ipsum')
      end
    end

    describe 'with missing \end{verbatim}' do
      let(:polytex) do <<-'EOS'
\begin{verbatim}
\emph{foo bar}
       EOS
      end

      it "should raise an error" do
        expect { processed_text }.to raise_error
      end
    end
  end

  describe "Verbatim environments" do
     let(:polytex) do <<-'EOS'
\begin{Verbatim}
\emph{foo bar}
\end{Verbatim}
       EOS
     end

    let(:output) { '\emph{foo bar}' }

      it { should resemble(output) }
      it { should_not resemble('\begin{Verbatim}') }
      it { should_not resemble('rend="tt"') }
      it { should resemble('<pre class="verbatim">') }
    end

  describe "raw equation environments" do
     let(:equation) do <<-'EOS'
\begin{equation}
\int_\Omega d\omega = \int_{\partial\Omega} \omega
\end{equation}
       EOS
     end
     let(:polytex) { equation }

    it { should resemble(equation) }
    it { should resemble('<div class="equation">') }
  end

  describe "equation environments surrounded by text" do
     let(:equation) do <<-'EOS'
\begin{equation}
\int_\Omega d\omega = \int_{\partial\Omega} \omega
\end{equation}
       EOS
     end
     let(:polytex) { "lorem\n" + equation + "\nipsum" }

    it { should resemble(equation) }
    it { should resemble('<div class="equation">') }
    it { should resemble('<p>lorem') }
    it { should resemble('<p class="noindent">ipsum') }
  end

  describe "display equations, LaTeX-style" do
    let(:equation) do <<-'EOS'
\[ \int_\Omega d\omega = \int_{\partial\Omega} \omega \]
     EOS
    end
    let(:polytex) { "lorem\n" + equation + "\nipsum" }

    # Tralics messes with the equation innards, so the result
    # doesn't resemble the whole equation. Use '\\Omega' as a decent proxy.
    it { should resemble('\\Omega') }
    it { should resemble('<div class="display_equation">') }
  end

  describe "display equations, TeX-style" do
    let(:equation) do <<-'EOS'
$$ \int_\Omega d\omega = \int_{\partial\Omega} \omega $$
     EOS
    end
    let(:polytex) { "lorem\n" + equation + "\nipsum" }

    # Tralics messes with the equation innards, so the result
    # doesn't resemble the whole equation. Use '\\Omega' as a decent proxy.
    it { should resemble('\\Omega') }
    it { should resemble('<div class="display_equation">') }
  end
end