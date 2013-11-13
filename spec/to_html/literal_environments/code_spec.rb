# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end
  subject(:processed_text) { Polytexnic::Core::Pipeline.new(polytex).to_html }

  describe "code blocks" do

    context "without syntax highlighting" do
      let(:polytex) do <<-'EOS'
        \begin{code}
        def foo
          "bar"
        end
        \end{code}
        EOS
      end

      it { should resemble 'def foo' }
      it { should resemble '<div class="code">' }
      it { should_not resemble '\begin{code}' }
    end

    context "with syntax highlighting" do
      let(:polytex) do <<-'EOS'
        %= lang:ruby
        \begin{code}
        def foo
          "bar"
        end
        \end{code}
        EOS
      end

      it do
        should resemble <<-'EOS'
          <div class="code">
            <div class="highlight">
              <pre>
                <span class="k">def</span> <span class="nf">foo</span>
                <span class="s2">"bar"</span>
                <span class="k">end</span>
              </pre>
            </div>
          </div>
        EOS
      end

      it { should resemble '<div class="code">' }
      it "should not have repeated code divs" do
        expect(processed_text.scan(/<div class="code">/).length).to eq 1
      end
      it { should resemble '<div class="highlight">' }
      it { should resemble '<pre>' }
    end
  end

  context "with a space after 'lang'" do
    let(:polytex) do <<-'EOS'
      %= lang: ruby
      \begin{code}
      def foo
        "bar"
      end
      \end{code}
      EOS
    end

    it do
      should resemble <<-'EOS'
        <div class="code">
          <div class="highlight">
            <pre>
              <span class="k">def</span> <span class="nf">foo</span>
              <span class="s2">"bar"</span>
              <span class="k">end</span>
            </pre>
          </div>
        </div>
      EOS
    end
  end

  describe "code inclusion" do
    context "for an existing file" do

      context "with no extension" do
        let(:polytex) do <<-'EOS'
          %= <<(Rakefile)
          EOS
        end
        let(:output) do <<-'EOS'
          <span class="n">require</span>
          EOS
        end
        it { should resemble output }
      end

      context "with an extension" do
        let(:polytex) do <<-'EOS'
          %= <<(spec/to_html/literal_environments/code_spec.rb)
          EOS
        end
        let(:output) do <<-'EOS'
          <div class="code">
            <div class="highlight">
              <pre><span class="c1"># encoding=utf-8</span>
          EOS
        end
        it { should resemble output }
        it { should_not include '<p></p>' }
      end

      context "with a custom language override" do
        let(:polytex) do <<-'EOS'
          %= << (polytexnic_commands.sty, lang: tex)
          EOS
        end
        let(:output) do <<-'EOS'
          <span class="c">% Add some custom commands needed by PolyTeXnic.</span>
          EOS
        end
        it { should resemble output }
        it { should_not include '<p></p>' }
      end
    end



    context "for a nonexistent file" do
      let(:polytex) do <<-'EOS'
        %= <<(foobar.rb)
        EOS
      end
      it { should include "ERROR: File 'foobar.rb' does not exist" }
    end
  end
end