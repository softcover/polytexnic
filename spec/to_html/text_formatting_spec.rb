# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "text formatting" do

    describe "italics" do
      let(:polytex) { '\emph{foo bar}' }
      it { should resemble '<em>foo bar</em>' }


      context "multiple instances" do
        let(:polytex) do
          '\emph{foo bar} and also \emph{baz quux}'
        end

        it { should resemble '<em>foo bar</em>' }
        it { should resemble '<em>baz quux</em>' }
      end
    end

    describe "boldface" do
      let(:polytex) { '\textbf{boldface}' }
      it { should resemble '<strong>boldface</strong>' }
    end

    describe "small caps" do
      let(:polytex) { '\textsc{small caps}' }
      it { should resemble '<span class="sc">small caps</span>' }
    end

    describe "small text" do
      let(:polytex) { '{\small small text}' }
      it { should resemble '<small>small text</small>' }
    end

    describe "typewriter text" do
      let(:polytex) { '\texttt{typewriter text}' }
      it { should resemble '<code class="tt">typewriter text</code>' }
    end

    describe "strikeout text" do
      let(:polytex) { '\sout{foo} bar' }
      it { should resemble '<del>foo</del> bar' }
    end

    describe "custom kode command" do
      let(:polytex) { '\kode{function\_name}' }
      it { should resemble '<code>function_name</code>' }
    end

    context "coloredtext" do
      describe "coloredtext command" do
        let(:polytex) { '\coloredtext{red}{text}' }
        it { should resemble '<span style="color: red">text</span>' }
      end

      context "coloredtexthtml command" do
        describe "with a lower-case hex color" do
          let(:polytex) { '\coloredtexthtml{ff0000}{text}' }
          it "should raise an error" do
            expect { processed_text }.to raise_error
          end
        end
        describe "with an upper-case hex color" do
          let(:polytex) { '\coloredtexthtml{FF0000}{text}' }
          it { should resemble '<span style="color: #FF0000">text</span>' }
        end
      end
    end
  end
end