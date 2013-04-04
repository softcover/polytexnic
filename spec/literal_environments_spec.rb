# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "verbatim environments" do
    let(:polytex) do <<-'EOS'
\begin{verbatim}
\emph{foo bar} & \\
\end{verbatim}
        EOS
    end

  let(:output) { '\emph{foo bar} &amp; \\\\' }

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

  describe "inline math, LaTeX-style" do
    let(:equation) do <<-'EOS'
\( \int_\Omega d\omega = \int_{\partial\Omega} \omega \)
     EOS
    end
    let(:polytex) { equation }
    let(:contents) { '\\Omega' }

    it { should resemble(contents) }
    it { should resemble('<span class="inline_math">') }    
  end

  describe "inline math, TeX-style" do
    let(:equation) do <<-'EOS'
$\int_\Omega d\omega = \int_{\partial\Omega} \omega$
     EOS
    end
    let(:polytex) { equation }
    let(:contents) { '\\Omega' }

    it { should resemble(contents) }
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
    let(:contents) { '\\Omega' }

    it { should resemble(contents) }
    it { should resemble('<div class="display_math">') }
  end

  describe "display math, TeX-style" do
    let(:equation) do <<-'EOS'
$$ \int_\Omega d\omega = \int_{\partial\Omega} \omega $$
     EOS
    end
    let(:polytex) { "lorem\n" + equation + "\nipsum" }
    let(:contents) { '\\Omega' }

    it { should resemble(contents) }
    it { should resemble('<div class="display_math">') }
  end

  shared_examples "an equation environment" do
    it { should resemble(contents) }
    it { should resemble('<div class="equation">') }
  end

  describe "raw equation environments" do
     let(:equation) do <<-'EOS'
\begin{equation}
\int_\Omega d\omega = \int_{\partial\Omega} \omega
\end{equation}
       EOS
     end
     let(:polytex) { equation }
     let(:contents) { equation }

    it_behaves_like "an equation environment"
  end

  describe "equation environments surrounded by text" do
    let(:equation) do <<-'EOS'
\begin{equation}
\int_\Omega d\omega = \int_{\partial\Omega} \omega
\end{equation}
       EOS
    end
    let(:polytex) { "lorem\n" + equation + "\nipsum" }
    let(:contents) { equation }

    it_behaves_like "an equation environment"
    it { should resemble('<p>lorem') }
    it { should resemble('<p class="noindent">ipsum') }
  end

  describe "align" do
    let(:equation) do <<-'EOS'
\begin{align}
x^2 + y^2 & = 1 \\
y & = \sqrt{1 - x^2}.
\end{align}
    EOS
    end
    let(:polytex) { equation }
    let(:contents) do <<-'EOS'
\begin{align}
x^2 + y^2 &amp; = 1 \\
y &amp; = \sqrt{1 - x^2}.
\end{align}
    EOS
    end

    it_behaves_like "an equation environment"
  end

  describe "align*" do
    let(:equation) do <<-'EOS'
\begin{align*}
x^2 + y^2 & = 1 \\
y & = \sqrt{1 - x^2}.
\end{align*}
    EOS
    end
    let(:polytex) { equation }
    let(:contents) do <<-'EOS'
\begin{align*}
x^2 + y^2 &amp; = 1 \\
y &amp; = \sqrt{1 - x^2}.
\end{align*}
    EOS
    end

    it_behaves_like "an equation environment"
  end

  describe "aligned" do
    let(:equation) do <<-'EOS'
\begin{aligned}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} & = \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} & = 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} & = \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} & = 0
\end{aligned}
    EOS
    end
    let(:polytex) { equation }
    let(:contents) do <<-'EOS'
\begin{aligned}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} &amp; = \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} &amp; = 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} &amp; = \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} &amp; = 0
\end{aligned}
    EOS
    end

    it_behaves_like "an equation environment"
  end

  describe "equation* with nesting" do
    let(:equation) do <<-'EOS'
\begin{equation*}
\left.\begin{aligned}
dE  &= \rho \\
d*B &= J + \dot{E}
\end{aligned}
\right\}
\qquad \text{Maxwell}
\end{equation*}
    EOS
    end
    let(:polytex) { equation }
    let(:contents) do <<-'EOS'
\begin{equation*}
\left.\begin{aligned}
dE  &amp;= \rho \\
d*B &amp;= J + \dot{E}
\end{aligned}
\right\}
\qquad \text{Maxwell}
\end{equation*}
    EOS
    end

    it_behaves_like "an equation environment"
  end

  describe "code blocks" do
    describe "without syntax highlighting" do
      let(:polytex) do <<-'EOS'
\begin{code}
def foo
  "bar"
end
\end{code}
      EOS
      end

      it { should resemble('def foo') }
      it { should resemble('<div class="code">') }
      it { should_not resemble('\begin{code}') }    
    end

    describe "with syntax highlighting" do
      let(:polytex) do <<-'EOS'
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}
      EOS
      end

      it { should resemble('<div class="code">') }
      it { should resemble('<div class="highlight">') }
      it { should resemble('<pre>') }
    end
  end
end