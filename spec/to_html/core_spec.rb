# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "Tralics installation" do
    before { File.delete(Polytexnic::Core::Utils.executable('tralics')) }
    subject { Polytexnic::Core::Utils.executable('tralics') }
    it { should include 'tralics' }
  end

  describe "comments" do
    let(:polytex) { "% A LaTeX comment" }
    it { should eq '' }

    context "with a section and lable" do
      let(:polytex) do <<-'EOS'
        % \section{Foo}
        % \label{sec:foo}
        EOS
      end
      it { should eq '' }
    end

    context "with a code listing" do
      let(:polytex) do <<-'EOS'
        % \begin{codelisting}
        % \heading{A hello program in Ruby.}
        % \label{code:hello}
        % %= lang:ruby
        % \begin{code}
        % def hello
        %   "hello, world!"
        % end
        % \end{code}
        % \end{codelisting}
        EOS
      end
      it { should eq '' }
    end

    context "with a literal percent" do
      let(:polytex) { '87.3\% of statistics are made up' }
      it { should resemble '87.3% of statistics are made up' }
    end

    context "With characters before the percent" do
      let(:polytex) { 'foo % bar' }
      it { should resemble 'foo' }
    end

    context "with two percent signs" do
      let(:polytex) { 'foo % bar % baz' }
      it { should resemble 'foo' }
    end

    context "with display math" do
      let(:polytex) do <<-'EOS'
        % \[
        % \begin{bmatrix}
        % 1 & \cdots & 0 \\
        % \vdots & \ddots & \vdots \\
        % 2 & \cdots & 0
        % \end{bmatrix}
        % \]
        EOS
      end
      it { should eq '' }
    end
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

  describe "double backslashes" do
    let(:polytex) { 'foo \\\\ bar' }
    let(:output) { 'foo <br /> bar' }
    it { should resemble output }
  end

  describe "unknown command" do
    let(:polytex) { '\foobar' }
    let(:output) { '' }
    it { should resemble output }
  end

  describe "href" do

    context "standard URL" do
      let(:polytex) { '\href{http://example.com/}{Example Site}' }
      let(:output) { '<a href="http://example.com/">Example Site</a>' }
      it { should resemble output }
    end

    context "URL needing encoding" do
      let(:url) { 'https://groups.google.com/~forum/!topic/mathjax%20users' }
      let(:polytex) { "\\href{#{url}}{Example Site}" }
      let(:output) { %(<a href="#{URI::encode(url)}">Example Site</a>) }
      it { should resemble output }
    end

    context "URL with hash for CSS id" do
      let(:url) { 'http://example.com/post#comments' }
      let(:polytex) { "\\href{#{url}}{Example Site}" }
      let(:output) { %(<a href="#{url}">Example Site</a>) }
      it { should resemble output }
    end
  end

  describe "centering" do
    let(:polytex) do <<-'EOS'
      \begin{center}
      Lorem ipsum

      dolor sit amet
      \end{center}
      EOS
    end
    let(:output) do <<-'EOS'
      <div class="center">
      <p>Lorem ipsum</p>

      <p>dolor sit amet</p>
      </div>
      EOS
    end
    it { should resemble output }
  end
end
