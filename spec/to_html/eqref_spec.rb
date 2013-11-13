# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Pipeline do
  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe 'equation \ref' do

      let(:equation) do <<-'EOS'
        \chapter{Equation test}

        \[ x^2 \]

        \begin{equation}
        \label{eq:foobar}
        x
        \end{equation}

       EOS
    end

    context 'with \ref{eq:foobar}' do
      let(:polytex) { equation + '\ref{eq:foobar}' }
      it { should include '1.1' }
    end

    context 'with \eqref{eq:foobar}' do
      let(:polytex) { equation + '\eqref{eq:foobar}' }
      it { should include '(<span class="ref">1.1</span>)' }
    end
  end
end