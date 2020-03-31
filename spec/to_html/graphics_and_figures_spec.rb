# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "graphics" do
    let(:polytex) do <<-'EOS'
      foo \includegraphics{foo.png} bar
      EOS
    end

    it do
      should resemble <<-'EOS'
        foo <span><span class="graphics">
        <img src="foo.png" alt="foo" /></span>
        </span>
      EOS
    end
    it { should_not resemble 'class="figure"' }
    it { should_not resemble 'Figure' }

    context "with a PDF image" do
      let(:polytex) do <<-'EOS'
        \includegraphics{foo.pdf}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <span class="graphics">
          <img src="foo.png" alt="foo" />
          </span>
        EOS
      end
    end

    context "with a Unicode filename" do
      let(:polytex) { '\includegraphics{images/grusväg.jpg}' }
      it { should include 'images/grusväg.jpg' }
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

    context "with an explicit center environment" do
      let(:polytex) do <<-'EOS'
        \begin{figure}
        \begin{center}
        lorem
        \end{center}
        \end{figure}
        EOS
      end
      it do
        should resemble <<-'EOS'
          <div class="center figure" id="uid1" data-tralics-id="uid1" data-number="1">
            <p>lorem</p>
            <div class="caption">
              <span class="header">Figure 1</span>
            </div>
          </div>
        EOS
      end
    end

    context "with a label and a cross-reference and a quote" do
      let(:polytex) do <<-'EOS'
        \begin{figure}
        \begin{quote}
        lorem
        \end{quote}
        \label{fig:foo}
        \end{figure}

        Figure~\ref{fig:foo} or Fig.~\ref{fig:foo}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="fig-foo" data-tralics-id="uid1" data-number="1" class="figure">
          <blockquote class="quotation">
            <p class="quote">lorem</p>
          </blockquote>
          <div class="caption">
            <span class="header">Figure 1</span>
          </div>
          </div>
          <p><a href="#fig-foo" class="hyperref">Figure <span class="ref">1</span></a>
              or
             <a href="#fig-foo" class="hyperref">Fig. <span class="ref">1</span></a>
          </p>
        EOS
      end
    end

    context "with included graphics" do
      let(:polytex) do <<-'EOS'
        \begin{figure}
        \includegraphics{images/foo.png}
        \label{fig:foo}
        \end{figure}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div id="fig-foo" data-tralics-id="uid1" data-number="1" class="figure">
          <span class="graphics">
            <img src="images/foo.png" alt="foo" />
          </span>
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
        \caption{This is a \emph{caption} with $x$.}
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
          <h1>
            <a href="#cid1" class="heading">
            <span class="number">Chapter 1 </span>The chapter</a>
          </h1>
          <div id="uid1" data-tralics-id="uid1" data-number="1.1" class="figure">
            <span class="graphics">
              <img src="foo.png" alt="foo" />
            </span>
            <div class="caption">
              <span class="header">Figure 1.1: </span>
              <span class="description">This is a <em>caption</em> with <span class="inline_math">\( x \)</span>.</span>
            </div>
          </div>
          <div id="uid2" data-tralics-id="uid2" data-number="1.2" class="figure">
            <span class="graphics">
              <img src="bar.png" alt="bar" />
            </span>
            <div class="caption">
              <span class="header">Figure 1.2: </span>
              <span class="description">This is another caption.</span>
            </div>
          </div>
          </div>
        EOS
      end
    end

    context "with a caption containing only a label" do
      let(:polytex) do <<-'EOS'
        \chapter{The chapter}

        \begin{figure}
        \includegraphics{foo.png}
        \caption{\label{fig:foo}}
        \end{figure}
         EOS
       end
       it { should     include 'Figure 1.1' }
       it { should_not include 'Figure 1.1:' }
     end

    context "with labels and cross-references" do
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

        Figure~\ref{fig:baz}

        \chapter{A second chapter}
        \label{cha:two}

        \begin{figure}
        \includegraphics{baz.png}
        \caption{Yet another.\label{fig:baz}}
        \end{figure}

        Figure~\ref{fig:foo} and Figure~\ref{fig:bar}
        EOS
       end

       it do
         should resemble <<-'EOS'
          <div id="cha-lorem_ipsum" data-tralics-id="cid1" class="chapter" data-number="1">
          <h1>
            <a href="#cha-lorem_ipsum" class="heading">
            <span class="number">Chapter 1 </span>The chapter</a>
          </h1>
          <div id="fig-foo" data-tralics-id="uid1" data-number="1.1" class="figure">
            <span class="graphics">
              <img src="foo.png" alt="foo" />
            </span>
            <div class="caption">
              <span class="header">Figure 1.1: </span>
              <span class="description">This is a caption.</span>
            </div>
          </div>
          <div id="fig-bar" data-tralics-id="uid2" data-number="1.2" class="figure">
            <span class="graphics">
              <img src="bar.png" alt="bar" />
            </span>
            <div class="caption">
              <span class="header">Figure 1.2: </span>
              <span class="description">This is another caption.</span>
            </div>
          </div>
          <p>
            <a href="#fig-baz" class="hyperref">Figure <span class="ref">2.1</span></a>
          </p>
          </div>
          <div id="cha-two" data-tralics-id="cid2" class="chapter" data-number="2">
          <h1>
            <a href="#cha-two" class="heading">
            <span class="number">Chapter 2 </span>A second chapter</a>
          </h1>
          <div id="fig-baz" data-tralics-id="uid3" data-number="2.1" class="figure">
            <span class="graphics">
              <img src="baz.png" alt="baz" />
            </span>
            <div class="caption">
              <span class="header">Figure 2.1: </span>
              <span class="description">Yet another.</span>
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

      context "with a centered image" do
        let(:polytex) do <<-'EOS'
          \chapter{The chapter}
          \label{cha:lorem_ipsum}

          \begin{figure}
          \centering
          \includegraphics{foo.png}
          \caption{This is a caption.\label{fig:foo}}
          \end{figure}
          EOS
         end

         it do
           should resemble <<-'EOS'
            <div id="cha-lorem_ipsum" data-tralics-id="cid1" class="chapter" data-number="1">
            <h1>
              <a href="#cha-lorem_ipsum" class="heading">
              <span class="number">Chapter 1 </span>The chapter</a>
            </h1>
            <div class="center figure" id="fig-foo" data-tralics-id="uid1" data-number="1.1">
              <span class="graphics">
                <img src="foo.png" alt="foo" />
              </span>
              <div class="caption">
                <span class="header">Figure 1.1: </span>
                <span class="description">This is a caption.</span>
              </div>
            </div>
            </div>
          EOS
        end

        context "using the \\image command and a PDF file image file" do
          let(:polytex) do <<-'EOS'
            \chapter{The chapter}
            \label{cha:lorem_ipsum}

            \begin{figure}
            \image{foo_bar.pdf}
            \caption{This is a caption.\label{fig:foo}}
            \end{figure}
            EOS
           end

           it do
             should resemble <<-'EOS'
              <div id="cha-lorem_ipsum" data-tralics-id="cid1" class="chapter" data-number="1">
              <h1>
                <a href="#cha-lorem_ipsum" class="heading">
                <span class="number">Chapter 1 </span>The chapter</a>
              </h1>
              <div id="fig-foo" data-tralics-id="uid1" data-number="1.1" class="figure">
                <div class="graphics image">
                  <img src="foo_bar.png" alt="foo_bar" />
                </div>
                <div class="caption">
                  <span class="header">Figure 1.1: </span>
                  <span class="description">This is a caption.</span>
                </div>
              </div>
              </div>
            EOS
          end
        end

        context "using the \\imagebox command and PDF image file" do
          let(:polytex) do <<-'EOS'
            \chapter{The chapter}
            \label{cha:lorem_ipsum}

            \begin{figure}
            \imagebox{foo_bar.pdf}
            \caption{This is a caption.\label{fig:foo}}
            \end{figure}
            EOS
           end

           it do
             should resemble <<-'EOS'
              <div id="cha-lorem_ipsum" data-tralics-id="cid1" class="chapter" data-number="1">
              <h1>
                <a href="#cha-lorem_ipsum" class="heading">
                <span class="number">Chapter 1 </span>The chapter</a>
              </h1>
              <div id="fig-foo" data-tralics-id="uid1" data-number="1.1" class="figure">
                <div class="graphics image box">
                  <img src="foo_bar.png" alt="foo_bar" />
                </div>
                <div class="caption">
                  <span class="header">Figure 1.1: </span>
                  <span class="description">This is a caption.</span>
                </div>
              </div>
              </div>
            EOS
          end
        end
      end
    end
  end
end
