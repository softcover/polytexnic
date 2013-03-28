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

  describe "inline math, LaTeX-style" do
    let(:equation) do <<-'EOS'
\( \int_\Omega d\omega = \int_{\partial\Omega} \omega \)
     EOS
    end
    let(:polytex) { equation }

    # Tralics messes with the equation innards, so the result
    # doesn't resemble the whole equation. Use '\\Omega' as a decent proxy.
    it { should resemble('\\Omega') }
    it { should resemble('<span class="inline_math">') }    
  end

  describe "inline math, TeX-style" do
    let(:equation) do <<-'EOS'
$\int_\Omega d\omega = \int_{\partial\Omega} \omega$
     EOS
    end
    let(:polytex) { equation }

    # Tralics messes with the equation innards, so the result
    # doesn't resemble the whole equation. Use '\\Omega' as a decent proxy.
    it { should resemble('\\Omega') }
    it { should resemble('<span class="inline_math">') }    
    it { should resemble('\\(') }
  end

  describe "multiple occurrences of inline math on one line" do
    let(:polytex) { "$\\Omega > 0$ and \\( x^2 - 2 \\equiv 0 \\) should work." }

    it { should resemble('\\Omega') }
    it { should resemble('\\equiv') }
    it { should resemble('<span class="inline_math">') }    
    it { should resemble('\\(') }
  end

  describe "display math, LaTeX-style" do
    let(:equation) do <<-'EOS'
\[ \int_\Omega d\omega = \int_{\partial\Omega} \omega \]
     EOS
    end
    let(:polytex) { "lorem\n" + equation + "\nipsum" }

    # Tralics messes with the equation innards, so the result
    # doesn't resemble the whole equation. Use '\\Omega' as a decent proxy.
    it { should resemble('\\Omega') }
    it { should resemble('<div class="display_math">') }
  end

  describe "display math, TeX-style" do
    let(:equation) do <<-'EOS'
$$ \int_\Omega d\omega = \int_{\partial\Omega} \omega $$
     EOS
    end
    let(:polytex) { "lorem\n" + equation + "\nipsum" }

    # Tralics messes with the equation innards, so the result
    # doesn't resemble the whole equation. Use '\\Omega' as a decent proxy.
    it { should resemble('\\Omega') }
    it { should resemble('<div class="display_math">') }
  end

  describe "align" do
    let(:equation) do <<-'EOS'
\begin{aligned}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} & = \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} & = 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} & = \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} & = 0
\end{aligned}
    EOS
    end
    let(:polytex) { equation }
    let(:escaped) do <<-'EOS'
\begin{aligned}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} &amp; = \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} &amp; = 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} &amp; = \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} &amp; = 0
\end{aligned}
    EOS
    end
    it { should resemble(escaped) }
    it { should resemble('<div class="equation">') }
  end
end