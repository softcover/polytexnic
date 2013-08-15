# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do

  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end

  describe '#to_polytex' do
    let(:processed_text) do
      Polytexnic::Core::Pipeline.new(source, format: :markdown).polytex
    end
    subject { processed_text }

    describe "for vanilla Markdown" do
      let(:source) { '*foo* **bar**' }
      it { should include('\emph{foo} \textbf{bar}') }
    end
  end
end