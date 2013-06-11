# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "comments" do
    let(:polytex) { "% A LaTeX comment" }
    it { should resemble "" }
  end

  describe "a complete document" do
    let(:polytex) do <<-'EOS'
      \documentclass{book}

      \begin{document}
      lorem ipsum
      \end{document}
      EOS
    end

    it { should resemble "<p>lorem ipsum</p>" }
  end

  describe "paragraphs" do
    let(:polytex) { 'lorem ipsum' }
    it { should resemble "<p>lorem ipsum</p>" }
    it { should_not resemble '<unknown>' }
  end

  describe "footnotes" do
    let(:polytex) { '\footnote{Foo}' }
    it do
      should resemble('<sup class="footnote">' +
                        '<a href="#footnote-1">1</a>' +
                      '</sup>')
    end
    it do
      out = '<div id="footnotes"><ol><li id="footnote-1">Foo</li></ol></div>'
      should resemble out
    end
  end

  describe '\maketitle' do
    let(:polytex) do <<-'EOS'
        \title{Foo}
        \subtitle{Bar}
        \author{Leslie Lamport}
        \date{Jan 1, 1971}
        \begin{document}
          \maketitle
        \end{document}
      EOS
    end

    it do
      should resemble <<-'EOS'
        <h1 class="title">Foo</h1>
        <h1 class="subtitle">Bar</h1>
        <h2 class="author">Leslie Lamport</h2>
        <h2 class="date">Jan 1, 1971</h2>
      EOS
    end

    it "should not have repeated title elements" do
      expect(processed_text.scan(/Leslie Lamport/).length).to eq 1
    end
  end

  describe "unknown command" do
    let(:polytex) { '\foobar' }
    let(:output) { '' }
    it { should resemble output }
  end

  describe "href" do
    let(:polytex) { '\href{http://example.com/}{Example Site}' }
    let(:output) { '<a href="http://example.com/">Example Site</a>' }
    it { should resemble output }
  end
end
