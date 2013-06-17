# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "quoted strings" do
    context "with single quotes" do
      let(:polytex) { "``foo bar''" }
      it { should resemble '“foo bar”' }
    end

    context "with single quotes" do
      let(:polytex) { "`foo bar'" }
      it { should resemble '‘foo bar’' }
    end

    context "with an apostrophe" do
      let(:polytex) { "don't stop believin'" }
      it { should resemble 'don’t stop believin’' }
    end
  end

  describe "dashes" do

    context "em" do
      let(:polytex) { '---' }
      it { should resemble '—' }
    end

    context "en" do
      let(:polytex) { '--' }
      it { should resemble '–' }
    end
  end

  describe '\ldots' do
    let(:polytex) { '\ldots' }
    it { should resemble '…' }
  end

  describe 'end-of-sentence punctuation' do
    let(:polytex) { 'Superman II\@. Lorem ipsum.' }
    it { should resemble 'Superman II. Lorem ipsum.' }
  end

  describe 'unbreakable interword space' do
    let(:polytex) { 'foo~bar' }
    it { should resemble 'foo bar' }
  end

 describe "(La)TeX logos" do

    describe "TeX logo" do
      let(:polytex) { '\TeX' }
      let(:output) do
        %(<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>)
      end
      it { should include(output) }
    end

    describe "LaTeX logo" do
      let(:polytex) { '\LaTeX' }
      let(:output) do
        %(<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">L<span style="text-transform: uppercase; font-size: 70%; margin-left: -0.36em; vertical-align: 0.3em; line-height: 0; margin-right: -0.15em;">A</span>T<span style="text-transform: uppercase; margin-left: -0.1667em; vertical-align: -0.5ex; line-height: 0; margin-right: -0.125em;">E</span>X</span>)
      end
      it { should include(output) }
    end

    describe "PolyTeX logo" do
      let(:polytex) { '\PolyTeX' }
      let(:output) do
        %(Poly<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>)
      end
      it { should include(output) }
    end

    describe "PolyTeXnic logo" do
      let(:polytex) { '\PolyTeXnic' }
      let(:output) do
        %(Poly<span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">T<span style="text-transform: uppercase; vertical-align: -0.5ex; margin-left: -0.1667em; margin-right: -0.125em;">E</span>X</span>nic)
      end
      it { should include(output) }
    end
  end
end