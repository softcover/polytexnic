# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe 'equation \ref' do

      let(:equation) do <<-'EOS'
        \chapter{Equation test}

        \begin{equation}
        \label{eq:foobar}
        x
        \end{equation}

       EOS
    end

    context 'with \ref{eq:foobar}' do
      let(:polytex) { equation + '\ref{eq:foobar}' }
      it { should include '1.1' }
      it { should pending 'Correct hyperref' }
    end

    context 'with \eqref{eq:foobar}' do
      let(:polytex) { equation + '\eqref{eq:foobar}' }
      it { should include '(1.1)' }
      it { should pending 'Correct hyperref' }
    end
  end
end