# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do


  describe '#to_latex' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_latex }
    subject { processed_text }

    describe "for vanilla LaTeX" do
      let(:polytex) { '\emph{foo}' }
      it { should include(polytex) }
    end

    describe "with source code highlighting" do
      let(:polytex) do <<-'EOS'
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}

\noindent lorem ipsum
        EOS
      end

      it { should resemble "commandchars=\\\\\\{" }
      it { should resemble '\begin{Verbatim}' }
      it { should resemble 'commandchars' }
      it { should resemble '\end{Verbatim}' }
      it { should_not resemble 'def foo' }
      it { should resemble '\noindent lorem ipsum' }

      describe "in the middle of a line" do
        let(:polytex) { 'Use \verb+%= lang:ruby+ to highlight Ruby code' }
        it { should resemble '\verb' }
        it { should_not resemble '<div class="highlight">' }
      end
    end

    context "with the metacode environment" do
      let(:polytex) do <<-'EOS'
%= lang:latex
\begin{metacode}
%= lang:ruby
\begin{code}
def foo
  "bar"
end
\end{code}
\end{metacode}

\noindent lorem ipsum
        EOS
      end

      it { should resemble "commandchars=\\\\\\{" }
      it { should_not resemble '%= lang:ruby' }
    end

    describe "verbatim environments" do
      let(:polytex) do <<-'EOS'
        \begin{verbatim}
        def foo
          "bar"
        end
        \end{verbatim}

        \begin{Verbatim}
        def foo
          "bar"
        end
        \end{Verbatim}
        EOS
      end

      it { should resemble polytex }

      context "containing an example of highlighted code" do
        let(:polytex) do <<-'EOS'
          \begin{verbatim}
          %= lang:ruby
          def foo
            "bar"
          end
          \end{verbatim}
          EOS
        end

        it { should resemble polytex }
      end
    end

    describe "hyperref links" do
      let(:polytex) do <<-'EOS'
        Chapter~\ref{cha:foo}
      EOS
      end
      let(:output) { '\hyperref[cha:foo]{Chapter~\ref{cha:foo}' }
      it { should resemble output }
    end
  end
end