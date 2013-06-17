# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  let(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }
  subject { processed_text }

  describe "quotations and verse" do
    describe '\quote' do
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
            <blockquote>
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
            <blockquote>
              <p>lorem ipsum</p>
              <blockquote>
              <p>foo bar</p>
              </blockquote>
              <p>dolor sit amet</p>
            </blockquote>
          EOS
        end
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
            <p>lorem ipsum</p>
            <p class="noindent">dolor sit amet</p>
          </blockquote>
        EOS
      end
    end
  end
end