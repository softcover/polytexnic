# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  describe '#process' do
    let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).process }
    subject { processed_text }

    describe "italics conversion" do
      let(:polytex) { '\emph{foo bar}' }
      it { should resemble('<em>foo bar</em>') }
    end

    describe "with multiple instances" do
      let(:polytex) do
        '\emph{foo bar} and also \emph{baz quux}'
      end

      it { should resemble('<em>foo bar</em>') }
      it { should resemble('<em>baz quux</em>') }
    end

    describe "quoted strings" do
      context "with single quotes" do
        let(:polytex) { "``foo bar''" }
        it { should resemble('“foo bar”') }
      end
    end

    describe "footnotes" do
      let(:polytex) { '\footnote{Foo}' }
      it do
        should resemble('<sup class="footnote">' + 
                          '<a href="#footnote-1">1</a>' +
                        '</sup>')
      end
      it do
        should resemble(
          '<div id="footnotes">' +
            '<div id="footnote-1" class="footnote">Foo</div>' +
          '</div>')
      end
    end

    describe "LaTeX logo" do
      let(:polytex) { '\LaTeX' }
      it { should resemble('<span class="LaTeX"></span>') }
    end

    describe '\ldots' do
      let(:polytex) { '\ldots' }
      it { should resemble('…') }
    end

    describe 'end-of-sentence punctuation' do
      let(:polytex) { 'Superman II\@. Lorem ipsum.' }
      it { should resemble('Superman II. Lorem ipsum.') }
    end

    describe 'unbreakable interword space' do
      let(:polytex) { 'foo~bar' }
      it { should resemble('foo bar') }
    end
  end
end