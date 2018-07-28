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

        context "with a sentence ending in a curly brace and closing quote" do
          let(:polytex) { "``Yes, \\emph{indeed!}'' A new sentence." }
          it { should resemble "“Yes, <em>indeed!</em>”#{intsp} A new sentence." }
        end

        context "with a sentence ending in a curly brace, closing quote, newline" do
          let(:polytex) { "``Yes, \\emph{indeed!}''\nA new sentence." }
          it { should resemble "“Yes, <em>indeed!</em>”#{intsp}\nA new sentence." }
        end

        context "with a sentence ending with curly braces" do
          let(:polytex) { "\\emph{\\textbf{Foo.}} Bar." }
          it { should resemble "#{intsp} Bar" }
        end

        context "with a sentence ending with curly braces and a newline" do
          let(:polytex) { "\\emph{\\textbf{Foo.}}\nBar." }
          it { should resemble "#{intsp} Bar" }
        end

        context "with a sentence ending with a square bracket" do
          let(:polytex) { "[It's foo.] Bar." }
          it { should resemble "#{intsp} Bar" }
        end

        context "with a sentence ending with a single quote and a paren" do
          let(:polytex) { "(It 'isn't.') Is it?"}
          it { should resemble "(It ’isn’t.’)#{intsp} Is it?" }
        end

        context "with a sentence ending with double quotes and a paren" do
          let(:polytex) { "(It ''isn't.'') Is it?"}
          it { should resemble "(It ”isn’t.”)#{intsp} Is it?" }
        end

        context "with a sentence ending with a single quote, paren, newline" do
          let(:polytex) { "(It 'isn't.')\nIs it?"}
          it { should resemble "(It ’isn’t.’)#{intsp} Is it?" }
        end

        context "with a sentence ending with double quotes, paren, newline" do
          let(:polytex) { "(It ''isn't.'')\nIs it?"}
          it { should resemble "(It ”isn’t.”)#{intsp} Is it?" }
        end

        context "with a mid-sentence footnote ending with a period" do
          let(:polytex) { 'Lorem\footnote{From \emph{Cicero}.} ipsum.' }
          it { should     include 'ipsum' }
          it { should_not include 'intersentencespace' }
        end

        context "with only a newline" do
          let(:polytex) { "Lorem ipsum.\nDolor sit amet." }
          it { should resemble "Lorem ipsum.#{intsp} Dolor sit amet." }
        end

        context "with a newline and space" do
          let(:polytex) { "Lorem ipsum.  \n  Dolor sit amet." }
          it { should resemble "Lorem ipsum.#{intsp} Dolor sit amet." }
        end

        context "with two newlines" do
          let(:polytex) { "Lorem ipsum.\n\nDolor sit amet." }
          it { should_not resemble "Lorem ipsum.#{intsp} Dolor sit amet." }
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
        %(<span class="texhtml">T<span class="texhtmlE">E</span>X</span>)
      end
      it { should include(output) }
    end

    describe "LaTeX logo" do
      let(:polytex) { '\LaTeX' }
      let(:output) do
        %(<span class="texhtml">L<span class="texhtmlA">A</span>T<span class="texhtmlE">E</span>X</span>)
      end
      it { should include(output) }
    end

    describe "PolyTeX logo" do
      let(:polytex) { '\PolyTeX' }
      let(:output) do
        %(Poly<span class="texhtml">T<span class="texhtmlE">E</span>X</span>)
      end
      it { should include(output) }
    end

    describe "PolyTeXnic logo" do
      let(:polytex) { '\PolyTeXnic' }
      let(:output) do
        %(Poly<span class="texhtml">T<span class="texhtmlE">E</span>X</span>nic)
      end
      it { should include(output) }
    end
  end
end
