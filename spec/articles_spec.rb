# encoding=utf-8
require 'spec_helper'

describe "articles" do
  let(:pipeline) { Polytexnic::Pipeline.new(polytex, article: true) }
  subject(:processed_text) { pipeline.to_html }

  let(:polytex) do <<-'EOS'
      Lorem ipsum
      \section{Foo}
      \label{sec:foo}

      \begin{figure}
      lorem
      \label{fig:foo}
      \end{figure}

      \begin{table}
      \begin{tabular}{cc}
      HTTP request & URL \\
      GET & /users \\
      GET & /users/1
      \end{tabular}
      \label{table:foo}
      \end{table}

      \begin{codelisting}
      \codecaption{Creating a \texttt{gem} configuration file. \\ \filepath{path/to/file}}
      \label{code:create_gemrc}
      %= lang:console
      \begin{code}
$ subl .gemrc
      \end{code}
      \end{codelisting}

      Listing~\ref{code:create_gemrc}

      Section~\ref{sec:foo}

      Figure~\ref{fig:foo}
    EOS
  end
  let(:section)   { '<a href="#sec-foo" class="heading"><span class="number">1 </span>' }
  let(:figure)    { '<span class="header">Figure 1</span>' }
  let(:table)     { '<span class="header">Table 1</span>' }
  let(:listing)   { '<span class="number">Listing 1:</span>' }

  let(:sref) { 'Section <span class="ref">1</span>' }
  let(:fref) { 'Figure <span class="ref">1</span>' }
  let(:lref) { 'Listing <span class="ref">1</span>' }

  describe "section" do
    describe "numbering" do
      it { should include section }
    end
    describe "xref" do
      it { should resemble sref }
    end
  end

  describe "figure" do
    describe "numbering" do
      it { should include figure }
    end
    describe "xref" do
      it { should resemble fref }
    end
  end

  describe "listing" do
    describe "numbering" do
      it { should include listing }
    end
    describe "xref" do
      it { should resemble lref }
    end
  end

end