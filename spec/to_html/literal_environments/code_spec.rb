# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Pipeline do
  before(:all) do
    FileUtils.rm('.highlight_cache') if File.exist?('.highlight_cache')
  end
  subject(:processed_text) { Polytexnic::Pipeline.new(polytex).to_html }

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

    context "with Unicode in the highlighting cache" do
      let(:polytex) do <<-'EOS'
        %= lang:console
        \begin{code}
        'foo★bar'
        \end{code}

        %= lang:console
        \begin{code}
        foo
        \end{code}
      EOS
      end
      before do
        # Create the broken highlight cache.
        Polytexnic::Pipeline.new(polytex).to_html
      end
      it "should not crash" do
        expect(File.exist?('.highlight_cache')).to be_true
        expect { Polytexnic::Pipeline.new(polytex).to_html }.not_to raise_error
      end
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

  context "with highlight and line numbering options" do
    let(:polytex) do <<-'EOS'
      %= lang:ruby, options: "hl_lines": [1, 2], "linenos": true
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
              <span class="lineno">1</span>
              <span class="hll">
                <span class="k">def</span> <span class="nf">foo</span>
              </span>
              <span class="lineno">2</span>
              <span class="hll">
                <span class="s2">"bar"</span>
              </span>
              <span class="lineno">3</span>
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
        it { should include '<pre>require' }
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

      context "with a section" do
        let(:polytex) do <<-'EOS'
          %= <<(spec/to_html/literal_environments/code_spec.rb[section_z])
          EOS
        end
        let(:output) do <<-'EOS'
          <div class="code">
            <div class="highlight">
              <pre>
                <span class="s2">"This is section_z; it's used by a test."</span>
                <span class="s2">"Section Z is your friend."</span>
              </pre>
            </div>
          EOS
        end
        it { should resemble output }
        it { should_not include '<span class="c1">#// begin section_z</span>' }
        it { should_not include '<span class="c1">#// end</span>' }

        context "that does not exist" do
          let(:polytex) do <<-'EOS'
            %= <<(spec/to_html/literal_environments/code_spec.rb[section_that_does_not_exist])
            EOS
          end
          let(:output) do <<-'EOS'
            <p>
              <span class="inline_verbatim">
                ERROR: Could not find section header '#// begin section_that_does_not_exist' in file 'spec/to_html/literal_environments/code_spec.rb'
              </span>
            </p>
            EOS
          end
          it { should resemble output }
        end
      end

      context "with a custom language override" do
        let(:polytex) do <<-'EOS'
          %= <<(polytexnic_commands.sty, lang: tex)
          EOS
        end
        let(:output) do <<-'EOS'
          <span class="c">% Add some custom commands needed by PolyTeXnic.</span>
          EOS
        end
        it { should resemble output }
        it { should_not include '<p></p>' }
      end

      context "with custom options" do
        let(:polytex) do <<-'EOS'
          %= <<(polytexnic_commands.sty, lang: tex, options: "hl_lines": [5])
          EOS
        end
        let(:output) do <<-'EOS'
          <span class="hll">
          EOS
        end
        it { should resemble output }
      end
    end



    context "for a nonexistent file" do
      let(:polytex) do <<-'EOS'
        %= <<(foobar.rb)
        EOS
      end
      it { should include "ERROR: File 'foobar.rb' does not exist" }
    end



    context "from a git tag" do
      shared_examples "an inclusion" do
        it "resembles the given output" do
          allow(Polytexnic::Literal::CodeInclusion::GitTaggedFileReader).to receive(:git).and_return(FakeGit.new)
          expect(processed_text).to resemble(output)
        end
      end

      context "the tag and file exist" do
        before(:all) do
          class FakeGit < Polytexnic::Literal::CodeInclusion::GitTaggedFileReader::Git
            # Write fake data to location on disk where git _would_ have placed the file
            def checkout(tmpdir, filename, tagname)
              f = File.join(tmpdir, filename)
              File.open(f, 'w') { |file| file.write("Fake data") }
            end
            def tag_exists?(tagname)
              true
            end
            def checkout_succeeded?(arg)
              true
            end
          end
        end

        context "with tag only" do
          let(:polytex) do <<-'EOS'
            %= <<(tagged_file.rb, tag: fake_tag.1.0)
            EOS
          end
          let(:output) do <<-'EOS'
            <div class="code">
              <div class="highlight">
                <pre>
                  <span class="no">Fake</span> <span class="n">data</span>
                </pre>
            </div>
            EOS
          end
          it_behaves_like "an inclusion"
        end

        context "with other params" do
          let(:output) do <<-'EOS'
            <div class="code">
              <div class="highlight">
                <pre>Fake data</pre>
              </div>
            </div>
            EOS
          end

          context "with tag and lang" do
            let(:polytex) do <<-'EOS'
              %= <<(tagged_file.rb, tag: slashes/and-dashes-are/ok/too, lang: tex)
              EOS
            end
            it_behaves_like "an inclusion"
          end

          context "with tag, lang and options" do
            let(:polytex) do <<-'EOS'
              %= <<(tagged_file.rb, tag: v0.9.4, lang: tex, options: "hl_lines": [5])
              EOS
            end
            it_behaves_like "an inclusion"
          end
        end
      end

      context "the tag does not exist" do
        before(:all) do
          class FakeGit < Polytexnic::Literal::CodeInclusion::GitTaggedFileReader::Git
            def checkout(tmpdir, filename, tagname)
            end
            def tag_exists?(tagname)
              false
            end
            def checkout_succeeded?(arg)
              false
            end
          end
        end

        let(:polytex) do <<-'EOS'
          %= <<(tagged_file.rb, tag: non_existent_tag)
          EOS
        end
        let(:output) do <<-'EOS'
          <p>
             <span class="inline_verbatim">
               ERROR: Tag 'non_existent_tag' does not exist.
             </span>
           </p>
           EOS
        end
        it_behaves_like "an inclusion"
      end

      context "the file does not exist" do
        before(:all) do
          class FakeGit < Polytexnic::Literal::CodeInclusion::GitTaggedFileReader::Git
            def checkout(tmpdir, filename, tagname)
              "pathspec #{tmpdir}/non_existent_file did not match any file(s) known to git.\n"
            end
            def tag_exists?(tagname)
              true
            end
            def checkout_succeeded?(arg)
              false
            end
          end
        end

        let(:polytex) do <<-'EOS'
          %= <<(non_existent_file, tag: v0.9.4)
          EOS
        end
        let(:output) do <<-'EOS'
          <p>
             <span class="inline_verbatim">
               ERROR: pathspec /non_existent_file did not match any file(s) known to git in tag v0.9.4.
             </span>
           </p>
           EOS
        end
        it_behaves_like "an inclusion"
      end

    end
  end
end


###################################################
'The following lines are used to test code sections'

#// begin section_a
"This is the code inside of section_a."
"Sections begin with a line containing only '#// begin section_name' and end with '#// end'"
"You many divide a file into multiple sections and include them individually in your book."
#// end

#// begin section_z
"This is section_z; it's used by a test."
"Section Z is your friend."
#// end
