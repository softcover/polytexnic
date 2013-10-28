# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do

  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end

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

      it { should resemble '\begin{framed_shaded}' + "\n" }
      it { should resemble "\n" + '\end{framed_shaded}' }
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

      it { should resemble '\begin{framed_shaded}' + "\n" }
      it { should resemble "\n" + '\end{framed_shaded}' }
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

      context "with an equation" do
        let(:polytex) do <<-'EOS'
          \begin{equation}
          \label{eq:x_y}
          x_y
          \end{equation}
          EOS
        end

        it { should resemble polytex }
        it { should_not resemble 'xmlelement' }
        it { should_not resemble 'xbox' }
        it "should have only one '\end{equation}'" do
          n_ends = processed_text.scan(/\\end{equation}/).length
          expect(n_ends).to eq 1
        end
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

    describe "asides" do

      context "with headings and labels" do
        let(:polytex) do <<-'EOS'
          \begin{aside}
          \heading{Foo \emph{are} bar.}
          \label{aside:foo}

          lorem ipsum

          \end{aside}
          EOS
        end

        let(:output) do <<-'EOS'
          \begin{shaded_aside}{Foo \emph{are} bar.}{aside:foo}

          lorem ipsum

          \end{shaded_aside}
          EOS
        end

        it { should resemble output }
      end
    end

    describe "href escaping" do
      context "URL needing encoding" do
        let(:url) { 'https://groups.google.com/~forum/!topic/mathjax users' }
        let(:polytex) { "\\href{#{url}}{Example Site}" }
        let(:output) { "\\href{#{URI::encode(url)}}" }
        it { should resemble output }
      end
    end
  end
end