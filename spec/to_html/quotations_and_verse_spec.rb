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
              <p>lorem ipsum</p>
              <p>dolor sit amet</p>
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
              <p>lorem ipsum</p>
              <blockquote class="quotation">
              <p>foo bar</p>
              </blockquote>
              <p>dolor sit amet</p>
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
            <p>lorem ipsum<span class="break"></span>
            dolor sit amet</p>
          </blockquote>
        EOS
      end
    end
  end
end