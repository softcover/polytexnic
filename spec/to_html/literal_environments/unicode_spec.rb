# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "non-ASCII Unicode" do
    let(:polytex) { 'Алексей Разуваев' }
    it { should include %(<span class="unicode">Алексей</span>) }
    it { should include %(<span class="unicode">Разуваев</span>) }
  end
end