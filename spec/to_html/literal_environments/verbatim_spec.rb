# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "verbatim environments" do

    context "alone" do
      let(:polytex) do <<-'EOS'
        \begin{verbatim}
        \emph{foo bar} & \\
        \end{verbatim}
        EOS
      end

      let(:output) { '\emph{foo bar} &amp; \\\\' }

      it { should resemble output }
      it { should resemble '<pre class="verbatim">' }
      it { should_not resemble '\begin{verbatim}' }
    end

    context "with nesting" do
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

      it { should resemble output }
      it "should break out of the loop if verbatim count is zero" do
        expect(processed_text).to resemble 'lorem ipsum'
      end
    end

    context 'with missing \end{verbatim}' do
      let(:polytex) do <<-'EOS'
        \begin{verbatim}
        \emph{foo bar}
       EOS
      end

      it "should raise an error" do
        expect { processed_text }.to raise_error
      end
    end

    context "containing a code environment" do
      let(:polytex) do <<-'EOS'
        \begin{verbatim}
        \begin{code}
        \emph{foo bar}
        \end{code}
        \end{verbatim}
        lorem ipsum
        EOS
      end

      let(:output) do <<-'EOS'
        \begin{code}
        \emph{foo bar}
        \end{code}
        EOS
      end

      it { should resemble output }
    end

    context "containing a highlighted code environment" do
      let(:polytex) do <<-'EOS'
        \begin{verbatim}
        %= lang:ruby
        \begin{code}
        foo ||= bar
        \end{code}
        \end{verbatim}
        lorem ipsum
        EOS
      end

      let(:output) do <<-'EOS'
        %= lang:ruby
        \begin{code}
        foo ||= bar
        \end{code}
        EOS
      end

      it { should resemble output }
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

    it { should resemble output }
    it { should_not resemble '\begin{Verbatim}' }
    it { should_not resemble 'rend="tt"' }
    it { should resemble '<pre class="verbatim">' }
  end
end