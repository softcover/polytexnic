# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe 'equation \ref' do

    context "with label eq:<something>" do
      let(:polytex) { '\ref{eq:foobar}' }
      it { should include polytex }
    end

    context 'with Eq.~\ref{<something>}' do
      let(:ref) { '\ref{foobar}' }
      let(:polytex) { "Eq.~#{ref}" }
      it { should include ref }
    end

    context 'with equation \ref{something}' do
      let(:ref) { '\ref{foobar}' }
      let(:polytex) { "equation #{ref}" }
      it { should include ref }
    end
  end

  describe '\eqref' do
    let(:polytex) { '\eqref{foobar}' }
    it { should include polytex }
  end
end