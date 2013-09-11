# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

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
    it { should_not resemble 'Figure' }
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

        Figure~\ref{fig:foo} or Fig.~\ref{fig:foo}
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
          <h1>
            <a href="#cid1" class="heading">
            <span class="number">Chapter 1 </span>The chapter</a>
          </h1>
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
          <h1>
            <a href="#cha-lorem_ipsum" class="heading">
            <span class="number">Chapter 1 </span>The chapter</a>
          </h1>
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
              <div class="graphics">
                <img src="foo.png" alt="foo" />
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