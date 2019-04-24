# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

  describe "quotations and verse" do
    describe '\begin{quote}...\end{quote}' do
      let(:polytex) { '\quote{foo}' }
      it { should resemble "<blockquote class=\"quote\">foo\n</blockquote>" }
    end

    describe "quote environment" do

      context "alone" do
        let(:polytex) do <<-'EOS'
          \begin{quote}
            lorem ipsum

            dolor sit amet
          \end{quote}
          EOS
        end

        it do
          should resemble <<-'EOS'
            <blockquote class="quotation">
              <p class="quote">lorem ipsum</p>
              <p class="quote">dolor sit amet</p>
            </blockquote>
          EOS
        end
      end

      context "nested" do
        let(:polytex) do <<-'EOS'
          \begin{quote}
            lorem ipsum

            \begin{quote}
              foo bar
            \end{quote}

            dolor sit amet
          \end{quote}
          EOS
        end
        it do
          should resemble <<-'EOS'
            <blockquote class="quotation">
              <p class="quote">lorem ipsum</p>
              <blockquote class="quotation">
              <p class="quote">foo bar</p>
              </blockquote>
              <p class="quote">dolor sit amet</p>
            </blockquote>
          EOS
        end
      end

      context "with a leading noindent" do
        let(:polytex) do <<-'EOS'
  \section{Up and running}

\begin{quotation}
\noindent I think of Chapter 1 as the ``weeding out phase'' in law school
\end{quotation}
          EOS
        end
        it { should_not include('noindent') }
      end

      context "inside a figure" do
        let(:polytex) do <<-'EOS'
\chapter{Manipulating files}
\label{cha:manipulating_files}

\begin{figure}
\begin{quote}
FRom faireſt creatures we deſire increaſe, \\
That thereby beauties \emph{Roſe} might neuer die, \\
But as the riper ſhould by time deceaſe, \\
His tender heire might beare his memory: \\
But thou contracted to thine owne bright eyes, \\
Feed'ſt thy lights flame with ſelfe ſubſtantiall fewell, \\
Making a famine where aboundance lies, \\
Thy ſelfe thy foe,to thy ſweet ſelfe too cruell: \\
Thou that art now the worlds freſh ornament, \\
And only herauld to the gaudy ſpring, \\
Within thine owne bud burieſt thy content, \\
And tender chorle makſt waſt in niggarding: \\
\quad Pitty the world,or elſe this glutton be, \\
\quad To eate the worlds due,by the graue and thee.\\
\end{quote}
\caption{A copy-and-pastable version of Shakespeare's first sonnet (\href{https://en.wikipedia.org/wiki/Cf.}{\emph{cf.}}\ Figure~\ref{fig:sonnet_1}).\label{fig:copy_paste_sonnet_1}}
\end{figure}
          EOS
        end
        it { should include('ſubſtantiall') }
      end
    end

    describe '\verse' do
      let(:polytex) { '\verse{foo}' }
      it { should resemble "<blockquote class=\"verse\">foo\n</blockquote>" }
    end

    describe "verse environment" do
      let(:polytex) do <<-'EOS'
        \begin{verse}
          lorem ipsum\\
          dolor sit amet
        \end{verse}
        EOS
      end
      it do
        should resemble <<-'EOS'
          <blockquote class="verse">
            <p class="quote">lorem ipsum<span class="break"></span>
            dolor sit amet</p>
          </blockquote>
        EOS
      end
    end
  end
end
