# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "comments" do
    let(:polytex) { "% A LaTeX comment" }
    it { should eq '' }

    context "with a section and label" do
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

    context "with a code inclusion" do
      let(:polytex) { '% %= << spec/spec_helper.rb' }
      it { should eq '' }
    end

    context "with a literal percent" do
      let(:polytex) { '87.3\% of statistics are made up' }
      it { should resemble '87.3% of statistics are made up' }
    end

    context "with characters before the percent" do
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

    context "with all element filled out explicitly" do
      let(:polytex) do <<-'EOS'
          \title{Foo \\ \emph{Bar}}
          \subtitle{Baz}
          \author{Michael Hartl}
          \date{January 1, 2013}
          \begin{document}
            \maketitle
          \end{document}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="title_page">
          <h1 class="title">Foo <span class="break"></span> <em>Bar</em></h1>
          <h1 class="subtitle">Baz</h1>
          <h2 class="author">Michael Hartl</h2>
          <h2 class="date">January 1, 2013</h2>
          </div>
        EOS
      end

      it "should not have repeated title elements" do
        expect(processed_text.scan(/Michael Hartl/).length).to eq 1
      end
    end

    context "when date is blank" do
      let(:polytex) do <<-'EOS'
          \title{Foo \\ \emph{Bar}}
          \subtitle{Baz}
          \author{Michael Hartl}
          \date{}
          \begin{document}
            \maketitle
          \end{document}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="title_page">
          <h1 class="title">Foo <span class="break"></span> <em>Bar</em></h1>
          <h1 class="subtitle">Baz</h1>
          <h2 class="author">Michael Hartl</h2>
          </div>
        EOS
      end
    end

    context "when date is missing" do
      let(:polytex) do <<-'EOS'
          \title{Foo \\ \emph{Bar}}
          \subtitle{Baz}
          \author{Michael Hartl}
          \begin{document}
            \maketitle
          \end{document}
        EOS
      end

      it { should resemble '<h2 class="date">' }
      it "should include today's date" do
        expect(processed_text).to resemble Date.today.strftime("%A, %b %e")
      end
    end
  end

  describe "double backslashes" do
    let(:polytex) { 'foo \\\\ bar' }
    let(:output) { 'foo <span class="break"></span> bar' }
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

    context "URL containing TeX" do
      let(:polytex) { '\href{http://example.com/}{\emph{\TeX}}' }
      let(:output) { '<a href="http://example.com/" class="tex">' }
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

  describe "skips" do

    context "bigskip" do
      let(:polytex) { '\bigskip' }
      it { should resemble '<p style="margin-top: 12.0pt"' }
    end

    context "medskip" do
      let(:polytex) { '\medskip' }
      it { should resemble '<p style="margin-top: 6.0pt"' }
    end

    context "smallskip" do
      let(:polytex) { '\smallskip' }
      it { should resemble '<p style="margin-top: 3.0pt"' }
    end
  end
end
