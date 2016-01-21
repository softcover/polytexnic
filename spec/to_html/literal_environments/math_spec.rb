# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Pipeline do
  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "display and inline math" do
    let(:math) do <<-'EOS'
      \begin{bmatrix}
      1 & \cdots & 0 \\
      \vdots & \ddots & \vdots \\
      2 & \cdots & 0
      \end{bmatrix}
      EOS
    end

    let(:result) do <<-'EOS'
      \begin{bmatrix}
      1 &amp; \cdots &amp; 0 \\
      \vdots &amp; \ddots &amp; \vdots \\
      2 &amp; \cdots &amp; 0
      \end{bmatrix}
      EOS
    end

    context "comment removal takes newline with it" do
      let(:polytex)  { "something % followed by comment\ncontinues"}
      let(:contents) { "<p>something continues\n</p>"}

      it { should resemble contents }
    end

    # bcs =$ in comment used to fail...
    context "math followed by comment with math in it" do
      let(:polytex)  { "some % comment =$\nmore $\\xi$ fin"}
      let(:contents) { "<p>some more <span class=\"inline_math\">\\( \\xi \\)</span> fin</p>"}

      it { should resemble contents }
    end

    context "newlines in inline math" do
      let(:equation) { "$\\sin\\theta\n\\cos\\theta$" }
      let(:polytex)  { equation }
      let(:contents) { "\\( \\sin\\theta\n\\cos\\theta \\)"}

      it { should resemble contents }
    end

    context "comments in inline math" do
      let(:equation) { "$\\sin\\theta % comment\n\\cos\\theta$" }
      let(:polytex)  { equation }
      let(:contents) { "\\( \\sin\\theta \\cos\\theta \\)"}

      it { should resemble contents }
    end

    context "comments in displaystyle math" do
      let(:equation) { "\\[ \\sin\\theta % a comment\n  % = mo comment \n\\cos\\theta \\]" }
      let(:polytex)  { equation }
      let(:contents) { "\\[ \\sin\\theta \n\\cos\\theta \\]"}

      it { should resemble contents }
    end

    context "comment followed by displaystyle math" do
      let(:equation) { "something\n% a comment\n\\[ \\sin\\theta \\]" }
      let(:polytex)  { equation }
      let(:contents) { "<p>something</p>\n<div class=\"equation\">\\[ \\sin\\theta \\]"}

      it { should resemble contents }
    end

    context "multiline comment followed by displaystyle math" do
      let(:equation) { "something:\n\t% c line1\n % c line2\n\t\\[\n\t\t\\cos\\theta\n\t\\]" }
      let(:polytex)  { equation }
      let(:contents) { "<p>something:</p>\n<div class=\"equation\">\\[ \n\t\\cos\\theta\n\\]"}

      it { should resemble contents }
    end

    context "math in comment followed by displaystyle" do
      let(:polytex)  { "as:\n%$x$\n%$y$:\n%nonmepty\n\\[ \\sin\\theta \\]\nMore $m$." }
      let(:contents) { "<p>as:</p>\n<div class=\"equation\">\\[ \\sin\\theta \\]\n</div><p class=\"noindent\">More <span class=\"inline_math\">\\( m \\)</span>."}

      it { should resemble contents }
    end

    context "empty comment line after math in comment" do
      let(:polytex)  { "as:\n%$x$\n%$y$:\n%\n\\[ \\sin\\theta \\]\nMore $m$." }
      let(:contents) { "<p>as:</p>\n<div class=\"equation\">\\[ \\sin\\theta \\]\n</div><p class=\"noindent\">More <span class=\"inline_math\">\\( m \\)</span>."}

      it { should resemble contents }
    end

    # WHAT IS THE DESIRED BEHAVIOUR?
    # context "non-removable comments also work" do
    #   let(:polytex)  { "$something %= yada\ncontinues$"}
    #   let(:contents) { "\\( something \\begin{xmlelement}{literalhtml}63e26c6f0c9fff746a67902d3b49f77897ba9500\\end{xmlelement}\ncontinues</span>\n</p>"}
    #
    #   it { should resemble contents }
    # end



    context "TeX displaystyle" do
      let(:equation) { "$$ #{math} $$"}
      let(:polytex)  { equation }
      let(:contents) { "\\[ #{result} \\]"}

      it { should resemble contents }
    end

    context "LaTeX displaystyle" do
      let(:equation) { "\\[ #{math} \\]"}
      let(:polytex)  { equation }
      let(:contents) { "\\[ #{result} \\]"}

      it { should resemble contents }

      context "with surrounding text" do
        let(:polytex) { "lorem\n\\[ #{math} \\]\nipsum" }
        it { should resemble '<p class="noindent">' }
      end
    end

    context "TeX inline" do
      let(:equation) { "$#{math}$"}
      let(:polytex)  { equation }
      let(:contents) { "\\( #{result} \\)"}

      it { should resemble contents }
    end

    context "TeX inline with a dollar sign" do
      let(:equation) { "$#{math} \\mbox{\\$2 bill}$"}
      let(:polytex)  { equation }
      let(:contents) { "\\( #{result} \\mbox{\\$2 bill} \\)"}

      it { should resemble contents }
    end

    context "LaTeX inline" do
      let(:equation) { "\\( #{math} \\)" }
      let(:polytex)  { equation }
      let(:contents) { "\\( #{result} \\)" }

      it { should resemble contents }
    end

    context "with a space before a dollar sign" do
      let(:polytex) { "foo $x$ bar" }
      let(:contents) { "<p>foo <span class=\"inline_math\">\\( x \\)</span> bar" }
      it { should include contents }
    end

    context 'using \ensuremath' do
      let(:math) { 'x^2 + y' }
      let(:equation) { "\\ensuremath{#{math}}" }
      let(:polytex)  { equation }
      let(:contents) { "\\( #{math} \\)" }
      it { should include contents }
    end
  end

  describe "multiple occurrences of inline math on one line" do
    let(:polytex) { '$\Omega > 0$ and \( x^2 - 2 \equiv 0 \) should work.' }

    it { should resemble '\Omega' }
    it { should resemble '\equiv' }
    it { should resemble '<span class="inline_math">' }
    it { should resemble '\(' }
  end

  describe "equation environments" do

    shared_examples "an equation environment" do
      it { should resemble contents }
      it { should resemble '<div' }
      it { should resemble 'class="equation"' }
    end

    context "alone" do
      let(:equation) do <<-'EOS'
        \begin{equation}
        \int_\Omega d\omega = \int_{\partial\Omega} \omega
        \end{equation}
      EOS
      end
      let(:polytex)  { equation }
      let(:contents) { equation }

      it_behaves_like "an equation environment"
    end

    context "with a label and cross-reference" do
      let(:equation) do <<-'EOS'
        \chapter{Foo}
        \begin{equation}
        \label{stokes_theorem}
        \int_\Omega d\omega = \int_{\partial\Omega} \omega
        \end{equation}

        Eq.~\eqref{stokes_theorem} or \eqref{stokes_theorem}
      EOS
      end
      let(:polytex)  { equation }
      let(:contents) do <<-'EOS'
        <div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h1><a href="#cid1" class="heading"><span class="number">Chapter 1 </span>Foo</a></h1>
        <div id="stokes_theorem" data-tralics-id="uid1" data-number="1.1" class="equation">
               \begin{equation}
               \label{stokes_theorem}
               \int_\Omega d\omega = \int_{\partial\Omega} \omega
               \end{equation}
        </div>
        <p class="noindent"><a href="#stokes_theorem" class="hyperref">Eq. (<span class="ref">1.1</span>)</a>
        or
        <a href="#stokes_theorem" class="hyperref">(<span class="ref">1.1</span>)</a>
        </p>
      EOS
      end

      it_behaves_like "an equation environment"
    end

    context "surrounded by text" do
      let(:equation) do <<-'EOS'
        \begin{equation}
        \int_\Omega d\omega = \int_{\partial\Omega} \omega
        \end{equation}
        EOS
      end
      let(:polytex)  { "lorem\n" + equation + "\nipsum" }
      let(:contents) { equation }

      it_behaves_like "an equation environment"
      it { should resemble '<p>lorem' }
      it { should resemble '<p class="noindent">ipsum' }
    end

    context "followed by a code listing" do
      let(:polytex) do <<-'EOS'
author be technical. (If you know how to use a command line and have a favorite text editor, you are technical enough to use Softcover.)

\begin{equation}
\label{eq:maxwell}
\left.\begin{aligned}
\nabla\cdot\mathbf{E} & = \rho \\
\nabla\cdot\mathbf{B} & = 0 \\
\nabla\times\mathbf{E} & = -\dot{\mathbf{B}} \\
\nabla\times\mathbf{B} & = \mathbf{J} + \dot{\mathbf{E}}
\end{aligned}
\right\}
\quad\text{Maxwell equations}
\end{equation}

\begin{codelisting}
\label{code:eval}
\codecaption{The caption.}
%= lang:scheme
\begin{code}
;; Implements Lisp in Lisp.
;; Alan Kay called this feat "Maxwell's equations of software", because just as
\end{code}
\end{codelisting}

        EOS
      end
      it { should_not resemble 'noindent="true"' }
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
        \begin{equation}
        \begin{aligned}
        \nabla \times \vec{\mathbf{B}} -\, \frac1c\,
        \frac{\partial\vec{\mathbf{E}}}{\partial t} & =
        \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} & =
        4 \pi \rho \\
        \nabla \times \vec{\mathbf{E}}\, +\, \frac1c\,
        \frac{\partial\vec{\mathbf{B}}}{\partial t} & = \vec{\mathbf{0}} \\
        \nabla \cdot \vec{\mathbf{B}} & = 0
        \end{aligned}
        \end{equation}
        EOS
      end
      let(:polytex) { equation }
      let(:contents) do <<-'EOS'
        \begin{equation}
        \begin{aligned}
        \nabla \times \vec{\mathbf{B}} -\, \frac1c\,
        \frac{\partial\vec{\mathbf{E}}}{\partial t} &amp; =
        \frac{4\pi}{c}\vec{\mathbf{j}} \\   \nabla \cdot \vec{\mathbf{E}} &amp;
        = 4 \pi \rho \\
        \nabla \times \vec{\mathbf{E}}\, +\, \frac1c\,
        \frac{\partial\vec{\mathbf{B}}}{\partial t} &amp; = \vec{\mathbf{0}} \\
        \nabla \cdot \vec{\mathbf{B}} &amp; = 0
        \end{aligned}
        \end{equation}
        EOS
      end

      it_behaves_like "an equation environment"
    end

    describe "equation*" do
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
  end
end