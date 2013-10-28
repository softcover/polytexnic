# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Core::Pipeline#to_html' do

  subject(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }

  describe "itemize" do
    let(:polytex) { '\itemize' }
    it { should resemble '<ul></ul>'}
  end

  describe "enumerate" do
    let(:polytex) { '\enumerate' }
    it { should resemble '<ol></ol>'}
  end

  describe "item" do
    let(:polytex) { '\item foo' }
    it { should resemble "<li>foo\n</li>"}
  end

  describe "itemized list" do

    context "alone" do
      let(:polytex) do <<-'EOS'
        \begin{itemize}
        \item Foo
        \item Bar
        \end{itemize}
        EOS
      end
      it do
        should resemble <<-'EOS'
          <ul>
          <li>Foo</li>
          <li>Bar</li>
          </ul>
        EOS
      end
    end

    context "preceded by text" do
      let(:polytex) do <<-'EOS'
        lorem ipsum

        \begin{itemize}
        \item Foo
        \item Bar
        \end{itemize}
        EOS
      end
      it do
        should resemble <<-'EOS'
          <p>lorem ipsum</p>
          <ul>
          <li>Foo</li>
          <li>Bar</li>
          </ul>
        EOS
      end
    end

    context "afollowed by text" do
      let(:polytex) do <<-'EOS'
        \begin{itemize}
        \item Foo
        \item Bar
        \end{itemize}

        lorem ipsum
        EOS
      end
      it do
       should resemble <<-'EOS'
          <ul>
          <li>Foo</li>
          <li>Bar</li>
          </ul><p>lorem ipsum
          </p>
        EOS
      end
    end
  end

  describe "enumerated list" do
    let(:polytex) do <<-'EOS'
      \begin{enumerate}
      \item Foo
      \item Bar
      \end{enumerate}
      EOS
    end
    it do
      should resemble <<-'EOS'
        <ol>
        <li>Foo</li>
        <li>Bar</li>
        </ol>
      EOS
    end
  end
end