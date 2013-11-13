# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

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


    describe "spaces" do

      context "thin" do
        let(:polytex) { 'a\,b' }
        it { should resemble 'a<span class="thinspace">&thinsp;</span>b' }
      end

      context "normal" do
        let(:polytex) { 'Dr.\ No' }
        it { should resemble 'Dr. No' }
      end

      context "intersentence" do
        let(:intsp) { '<span class="intersentencespace"></span>' }

        context "separated by a space" do
          let(:polytex) { 'I am. You are.' }
          it { should resemble "I am.#{intsp} You are." }
        end

        context "separated by n spaces" do
          let(:polytex) { 'I am!     You are.' }
          it { should resemble "I am!#{intsp} You are." }
        end

        context "separated by a newline" do
          let(:polytex) { "I am?\nYou are." }
          it { should resemble "I am?#{intsp} You are." }
        end

        context "separated by two newlines" do
          let(:polytex) { "I am.\n\nYou are." }
          it { should resemble 'I am.</p><p>You are.' }
        end

        context "with a sentence ending in a closing parenthesis" do
          let(:polytex) { "(Or otherwise.) A new sentence." }
          it { should resemble "(Or otherwise.)#{intsp} A new sentence." }
        end

        context "with a sentence ending in a closing quote" do
          let(:polytex) { "``Yes, indeed!'' A new sentence." }
          it { should resemble "“Yes, indeed!”#{intsp} A new sentence." }
        end

        context "forced inter-sentence override" do
          let(:polytex) { 'Superman II\@. Lorem ipsum.' }
          it { should resemble "Superman II.#{intsp} Lorem ipsum." }
        end
      end
    end
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