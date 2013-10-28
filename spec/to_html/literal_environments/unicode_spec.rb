# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  subject(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }

  describe "non-ASCII Unicode" do
    let(:polytex) { 'Алексей Разуваев' }
    it { should include %(<span class="unicode">Алексей</span>) }
    it { should include %(<span class="unicode">Разуваев</span>) }
  end
end