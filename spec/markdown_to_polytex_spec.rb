# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do

  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end

  describe '#to_polytex' do
    let(:processed_text) do
      Polytexnic::Core::Pipeline.new(source, source: :markdown).polytex
    end
    subject { processed_text }

    describe "for vanilla Markdown" do
      let(:source) { '*foo* **bar**' }
      it { should include '\emph{foo} \textbf{bar}' }
      it { should_not include '\begin{document}' }
    end

    describe "for multiline Markdown" do
      let(:source) do <<-EOS
# A chapter

Hello, *world*!

## A section

Lorem ipsum
        EOS
      end
      it { should include '\chapter{A chapter}' }
      it { should include '\section{A section}' }
      it { should_not include '\hypertarget' }
    end
  end
end