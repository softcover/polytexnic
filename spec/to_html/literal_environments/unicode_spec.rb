# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Pipeline do
  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "non-ASCII Unicode" do
    let(:polytex) { 'Алексей Разуваев' }
    it { should include 'Алексей Разуваев' }
  end
end