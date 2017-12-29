# encoding=utf-8
require 'spec_helper'

describe 'Polytexnic::Pipeline#to_html' do

  let(:pipeline) { Polytexnic::Pipeline.new(polytex) }
  subject(:processed_text) { pipeline.to_html }

 describe '\input command' do
    let(:external_file) { 'foo.tex' }
    let(:nested_external_file) { 'bar.tex' }
    let(:input) do <<-'EOS'
Lorem ipsum \href{http://example.com/}{example}
%= lang:ruby
\begin{code}
def foo; 'foo'; end
\end{code}
Lorem \emph{ipsum} dolor sit amet

\input{bar}
      EOS
    end
    let(:nested_input) do <<-'EOS'
Lorem ipsum
%= lang:python
\begin{code}
def bar(): return "bar"
\end{code}
      EOS
    end
    before do
      File.write(external_file, input)
      File.write(nested_external_file, nested_input)
    end
    after do
      File.unlink(external_file)
      File.unlink(nested_external_file)
    end

    let(:polytex) { "\\chapter{Foo}\n\n  \\input{foo}  " }
    let(:foo_html) do
      '<div class="code"><div class="highlight"><pre><span></span><span class="k">def</span> <span class="nf">foo</span>'
    end
    let(:bar_html) do
      '<div class="code"><div class="highlight"><pre><span></span><span class="k">def</span> <span class="nf">bar</span><span class="p">():'
    end

    it { should include foo_html }
    it { should include bar_html }
    it { should include '<a href="http://example.com/"' }
    it { should include '>example</a>' }
  end
end