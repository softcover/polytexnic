require 'spec_helper'

describe Polytexnic::Core do
  it { should respond_to(:polytex_to_html_fragment) }

  describe '#polytex_to_html' do
    subject { Polytexnic::Core.polytex_to_html_fragment(polytex) }

    describe "italics conversion" do
      let(:polytex) { '\emph{foo bar}' }
      it { should match(/<em>foo bar<\/em>/) }
    end

    describe "with multiple instances" do
      let(:polytex) do
        '\emph{foo bar} and also \emph{baz quux}'
      end

      it { should match(/<em>foo bar<\/em>/)}
      it { should match(/<em>baz quux<\/em>/) }
    end
  end
end