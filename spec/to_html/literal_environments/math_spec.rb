# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "inline math" do

    context "LaTeX-style" do
      let(:equation) do <<-'EOS'
        \( \int_\Omega d\omega = \int_{\partial\Omega} \omega \)
        EOS
      end
      let(:polytex) { equation }
      let(:contents) { '\Omega' }

      it { should resemble contents }
      it { should resemble '<span class="inline_math">' }
    end

    context "TeX-style" do
      let(:equation) do <<-'EOS'
        $\int_\Omega d\omega = \int_{\partial\Omega} \omega$
        EOS
      end
      let(:polytex) { equation }
      let(:contents) { '\Omega' }

      it { should resemble contents }
      it { should resemble '<span class="inline_math">' }
      it { should resemble '\(' }
    end
  end

  describe "multiple occurrences of inline math on one line" do
    let(:polytex) { '$\Omega > 0$ and \( x^2 - 2 \equiv 0 \) should work.' }

    it { should resemble '\Omega' }
    it { should resemble '\equiv' }
    it { should resemble '<span class="inline_math">' }
    it { should resemble '\(' }
  end

  describe "display math" do

    context "LaTeX-style" do
      let(:equation) do <<-'EOS'
        \[ \int_\Omega d\omega = \int_{\partial\Omega} \omega \]
        EOS
      end
      let(:polytex) { "lorem\n" + equation + "\nipsum" }
      let(:contents) { '\Omega' }

      it { should resemble contents }
      it { should resemble '<div class="display_math">' }
    end

    context "TeX-style" do
      let(:equation) do <<-'EOS'
        $$ \int_\Omega d\omega = \int_{\partial\Omega} \omega $$
        EOS
      end
      let(:polytex) { "lorem\n" + equation + "\nipsum" }
      let(:contents) { '\Omega' }

      it { should resemble contents }
      it { should resemble '<div class="display_math">' }
    end
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
        \label{eq:stokes_theorem}
        \int_\Omega d\omega = \int_{\partial\Omega} \omega
        \end{equation}

        Eq.~\eqref{eq:stokes_theorem} or \eqref{eq:stokes_theorem}
      EOS
      end
      let(:polytex)  { equation }
      let(:contents) do <<-'EOS'
        <div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h3><a href="#cid1" class="heading"><span class="number">1 </span>Foo</a></h3>
        <div id="eq-stokes_theorem" data-tralics-id="uid1" data-number="1.1" class="equation">
               \begin{equation}
               \label{eq:stokes_theorem}
               \int_\Omega d\omega = \int_{\partial\Omega} \omega
               \end{equation}
        </div>
        <p class="noindent"><a href="#eq-stokes_theorem" class="hyperref">Eq. (<span class="ref">1.1</span>)</a>
        or
        <a href="#eq-stokes_theorem" class="hyperref">(<span class="ref">1.1</span>)</a>
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