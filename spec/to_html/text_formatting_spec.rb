# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

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

    describe "typewriter text" do
      let(:polytex) { '\texttt{typewriter text}' }
      it { should resemble '<span class="tt">typewriter text</span>' }
    end
  end
end