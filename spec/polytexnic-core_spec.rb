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

  describe "graphics" do
    let(:polytex) do <<-'EOS'
\includegraphics{foo.png}
      EOS
    end

    it do
      should resemble <<-'EOS'
<div class="graphics">
<img src="foo.png" alt="foo" />
</div>
      EOS
    end
  end

  describe "figures" do
    let(:polytex) do <<-'EOS'
\begin{figure}
lorem
\end{figure}
      EOS
    end

    it do
      should resemble <<-'EOS'
<div id="uid1" data-tralics-id="uid1" data-number="1" class="figure">
<p>lorem</p>
<div class="caption">
  <span class="header">Figure 1</span>
</div>
</div>
      EOS
    end

    context "with a label and a cross-reference" do
      let(:polytex) do <<-'EOS'
\begin{figure}
lorem
\label{fig:foo}
\end{figure}

Figure~\ref{fig:foo}
        EOS
      end

      it do
        should resemble <<-'EOS'
<div id="fig-foo" data-tralics-id="uid1" data-number="1" class="figure">
<p>lorem</p>
<div class="caption">
  <span class="header">Figure 1</span>
</div>
</div>
<p><a href="#fig-foo" class="hyperref">Figure <span class="ref">1</span></a></p>
        EOS
      end
    end

    context "with included graphics" do
      let(:polytex) do <<-'EOS'
\begin{figure}
\includegraphics{images/foo.png}
\end{figure}
        EOS
      end

      it do
        should resemble <<-'EOS'
<div id="uid1" data-tralics-id="uid1" data-number="1" class="figure">
<div class="graphics">
  <img src="images/foo.png" alt="foo" />
</div>
<div class="caption">
  <span class="header">Figure 1</span>
</div>
</div>
        EOS
      end
    end

    context "with a caption" do
      let(:polytex) do <<-'EOS'
\chapter{The chapter}

\begin{figure}
\includegraphics{foo.png}
\caption{This is a caption.}
\end{figure}

\begin{figure}
\includegraphics{bar.png}
\caption{This is another caption.}
\end{figure}
         EOS
       end

       it do
         should resemble <<-'EOS'
<div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1">
<h3>
  <a href="#cid1" class="heading">
  <span class="number">1 </span>The chapter</a>
</h3>
<div id="uid1" data-tralics-id="uid1" data-number="1.1" class="figure">
  <div class="graphics">
    <img src="foo.png" alt="foo" />
  </div>
  <div class="caption">
    <span class="header">Figure 1.1: </span>
    <span class="description">This is a caption.</span>
  </div>
</div>
<div id="uid2" data-tralics-id="uid2" data-number="1.2" class="figure">
  <div class="graphics">
    <img src="bar.png" alt="bar" />
  </div>
  <div class="caption">
    <span class="header">Figure 1.2: </span>
    <span class="description">This is another caption.</span>
  </div>
</div>
</div>
        EOS
      end
    end

    context "with labels and cross-reference" do
      let(:polytex) do <<-'EOS'
\chapter{The chapter}
\label{cha:lorem_ipsum}

\begin{figure}
\includegraphics{foo.png}
\caption{This is a caption.\label{fig:foo}}
\end{figure}

\begin{figure}
\includegraphics{bar.png}
\caption{This is another caption.\label{fig:bar}}
\end{figure}


Figure~\ref{fig:foo} and Figure~\ref{fig:bar}
         EOS
       end

       it do
         should resemble <<-'EOS'
<div id="cha-lorem_ipsum" data-tralics-id="cid1" class="chapter" data-number="1">
<h3>
  <a href="#cha-lorem_ipsum" class="heading">
  <span class="number">1 </span>The chapter</a>
</h3>
<div id="fig-foo" data-tralics-id="uid1" data-number="1.1" class="figure">
  <div class="graphics">
    <img src="foo.png" alt="foo" />
  </div>
  <div class="caption">
    <span class="header">Figure 1.1: </span>
    <span class="description">This is a caption.</span>
  </div>
</div>
<div id="fig-bar" data-tralics-id="uid2" data-number="1.2" class="figure">
  <div class="graphics">
    <img src="bar.png" alt="bar" />
  </div>
  <div class="caption">
    <span class="header">Figure 1.2: </span>
    <span class="description">This is another caption.</span>
  </div>
</div>
<p>
  <a href="#fig-foo" class="hyperref">Figure <span class="ref">1.1</span></a>
  and
  <a href="#fig-bar" class="hyperref">Figure <span class="ref">1.2</span></a>
</p>
</div>
        EOS
      end
    end
  end

  describe "code listings" do
    let(:polytex) do <<-'EOS'
\chapter{Foo bar}

\begin{codelisting}
Creating a gem configuration file.
\label{code:create_gemrc}
%= lang:console
\begin{code}
$ subl .gemrc
\end{code}
\end{codelisting}

Listing~\ref{code:create_gemrc}
      EOS
    end

    it do
      should resemble <<-'EOS'
<div id="cid1" data-tralics-id="cid1" class="chapter" data-number="1"><h3><a href="#cid1" class="heading"><span class="number">1 </span>Foo bar</a></h3>
<div id="code-create_gemrc" data-tralics-id="uid1" class="codelisting" data-number="1.1">
  <div class="listing">
    <span class="header">Listing 1.1.</span>
    <span class="description">Creating a gem configuration file.</span>
  </div>
  <div class="code">
    <div class="highlight">
      <pre><span class="gp">$</span> subl .gemrc</pre>
    </div>
  </div>
</div>
<p><a href="#code-create_gemrc" class="hyperref">Listing <span class="ref">1.1</span></a></p>
</div>
      EOS
    end
  end
end
