# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "comments" do
    let(:polytex) { "% A LaTeX comment" }
    it { should eq '' }

    context "occurring a the end of a line" do
      let(:polytex) do <<-'EOS'
        lorem ipsum
        dolor sit amet.%this is a comment
        EOS
      end
      it { should include("amet.") }
    end

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

    context "with a percent-equals" do

      context "with an opening tag" do
        let(:polytex) { '%= <span id="foo" class="bar">' }
        it { should eq '<span id="foo" class="bar">' }
      end

      context "with a closing tag" do
        let(:polytex) { '%= </span>' }
        it { should eq '</span>' }
      end
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

  describe "a manual break" do
    let(:polytex) { 'foo \\\\ bar' }
    it { should include '<span class="break">' }
  end


  describe "paragraphs" do
    let(:polytex) { 'lorem ipsum' }
    it { should resemble "<p>lorem ipsum</p>" }
    it { should_not resemble '<unknown>' }
  end

  describe "explicit noindent" do
    let(:polytex) { '\noindent lorem ipsum' }
    it { should resemble '<p class="noindent">lorem ipsum</p>' }
  end

  describe "free span" do
    let(:polytex) do <<-'EOS'
\chapter{Basics} % (fold)
\label{cha:basics}

%= <span class="free"></span>
      EOS
    end

    it { should resemble('<span class="free"></span>') }
    it { should_not resemble('<p><span class="free"></span></p>') }
  end


  describe '\maketitle' do

    context "with all elements filled out explicitly" do
      let(:polytex) do <<-'EOS'
          \title{Foo \\ \emph{Bar}}
          \subtitle{\href{http://example.com/}{Baz}}
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
          <h1 class="subtitle"><a href="http://example.com/" target="_blank" rel="noopener">Baz</a></h1>
          <h2 class="author">Michael Hartl</h2>
          <h2 class="date">January 1, 2013</h2>
          </div>
        EOS
      end

      it "should not have repeated title elements" do
        expect(processed_text.scan(/Michael Hartl/).length).to eq 1
      end
    end

    context "with Unicode" do
      let(:polytex) do <<-'EOS'
          \title{A könyv címe}
          \subtitle{Alcím - itt lesz az alcím}
          \author{Árvíztűrő fúrógép}
          \date{January 1, 2013}
          \begin{document}
            \maketitle
          \end{document}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="title_page">
            <h1 class="title">A könyv címe</h1>
            <h1 class="subtitle">Alcím - itt lesz az alcím</h1>
            <h2 class="author">Árvíztűrő fúrógép</h2>
            <h2 class="date">January 1, 2013</h2>
          </div>
        EOS
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

  describe "URLs" do

    context "standard URL" do
      let(:polytex) { '\href{http://example.com/}{Example Site}' }
      it { should include '<a href="http://example.com/"' }
      it { should include '>Example Site</a>' }
    end

    context "containing TeX" do
      let(:polytex) { '\href{http://example.com/}{\emph{\TeX}}' }
      it { should include '<a href="http://example.com/"' }
      it { should include 'class="tex"' }
    end

    context "containing escaped text" do
      let(:polytex) { '\href{http://example.com/escaped\_text}{Example Site}' }
      it { should include '<a href="http://example.com/escaped_text"' }
      it { should include '>Example Site</a>' }
    end

    context "containing an escaped percent" do
      let(:polytex) { '\href{http://example.com/escaped\%20text}{Example Site}' }
      it { should include '<a href="http://example.com/escaped%20text"' }
      it { should include '>Example Site</a>' }
    end

    context "self-linking URL" do
      let(:polytex) { '\url{http://example.com/}' }
      it { should include '<a href="http://example.com/"' }
      it { should include '>http://example.com/</a>' }
    end

    context "with a # sign" do
      let(:polytex) { '\href{http://example.com/\#email}{email link}' }
      it { should include 'http://example.com/#email' }
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

  describe "ignored commands" do
    context "\\pbox" do
      let(:polytex) { '\pbox{12cm}{The cumulative CPU time}' }
      it { should_not include '12cm' }
    end

    context "\\includepdf" do
      let(:polytex) { '\includepdf{images/cover.pdf}' }
      it { should_not include 'images/cover.pdf' }
    end

    context "\\newunicodecharacter" do
      let(:polytex) { '\newunicodechar{├}{\textSFviii}' }
      it { should_not include '├' }
    end

    context "\\newpage" do
      let(:polytex) { '\newpage' }
      it { should_not include 'newpage' }
    end

    context "\\allowbreak" do
      let(:polytex) { '\allowbreak' }
      it { should_not include 'allowbreak' }
    end
  end
end
