require 'spec_helper'

describe Polytexnic::Core do
  it { should respond_to(:polytex_to_html_fragment) }

  describe '#polytex_to_html' do
    subject { Polytexnic::Core.polytex_to_html_fragment(polytex) }

    describe "italics conversion" do
      let(:polytex) { '\emph{foo bar}' }
      it { should =~ /foo bar/ }
    end
  end
end