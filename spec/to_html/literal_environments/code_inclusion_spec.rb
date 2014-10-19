# encoding=utf-8
require 'spec_helper'

describe "CodeInclusion::Args" do

  context "file only" do
    let(:line) {'%= <<(file.rb)'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({filename: "file.rb"})}
  end

  context "file and section" do
    let(:line) {'%= <<(file.rb[section1])'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({filename: "file.rb", section: 'section1'})}
  end

  context "file and line numbers" do
    let(:line) {'%= <<(file.rb[6,14-37,80])'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({filename: "file.rb",
                   line_numbers:  "6,14-37,80"})}
  end

  context "file and unquoted git repo" do
    let(:line) {'%= <<(file.rb, git: {repo: repo_path/.git})'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({ filename: "file.rb",
                    git:      { tag: nil, repo: 'repo_path/.git' }})}
  end

  context "file and double quoted git repo" do
    let(:line) {'%= <<(file.rb, git: {repo: "repo_path/.git"})'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({ filename: "file.rb",
                    git:      { tag: nil, repo: 'repo_path/.git' }})}
  end

  context "file and single quoted git repo" do
    let(:line) {"%= <<(file.rb, git: {repo: 'repo_path/.git'})"}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({ filename: "file.rb",
                    git:      { tag: nil, repo: 'repo_path/.git' }})}
  end

  context "file and git tag/repo" do
    let(:line) {'%= <<(file.rb, git: {tag: 1.0, repo: "repo_path/.git"})'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({ filename: "file.rb",
                    git:      { tag:  '1.0', repo: 'repo_path/.git' }})}
  end

  context "file and git repo/tag" do
    let(:line) {'%= <<(file.rb, git: {repo: "repo_path/.git", tag: 1.0})'}
    subject { CodeInclusion::Args.new(line).retrieval}

    it {should eq({ filename: "file.rb",
                    git:      { tag:  '1.0', repo: 'repo_path/.git' }})}
  end

  context "nearly everything" do
    let(:line) {'%= <<(file.rb[6-14,37], git: {repo: "repo_path/.git", tag: 1.0}, lang: tex, options: "hl_lines": [5]))'}

    describe "retrival args" do
      subject { CodeInclusion::Args.new(line).retrieval}

      it {should eq({ filename:     "file.rb",
                      line_numbers: "6-14,37",
                      git:          { tag:  '1.0', repo: 'repo_path/.git' }})}
    end

    describe "render args" do
      subject { CodeInclusion::Args.new(line).render}

      it {should eq({ custom_language:  "tex",
                      highlight:        ', options: "hl_lines": [5])'})}

    end
  end
end


describe "full listing" do

  describe "file" do

    context "exists" do
      let(:args) { {filename: __FILE__} }
      subject { CodeInclusion::FullListing::File.new(args).lines }

      it { should eq(File.read(__FILE__).split("\n")) }
    end

    context "does not exist" do
      let(:args) { {filename: "badfile"} }
      subject { lambda { CodeInclusion::FullListing::File.new(args).lines } }

      it { should raise_exception(CodeInclusion::RetrievalException) }
    end

  end

  describe "git tag" do

    context "file exists" do
      before(:all) do
        class FakeGitCmd < CodeInclusion::FullListing::GitTag::GitCmd
          def show
            "Real data\nsecond line"
          end
          def repository_exists?
            true
          end
          def tag_exists?
            true
          end
          def succeeded?
            true
          end
        end
      end

      let(:args) { { filename: "goodfile", git: {tag: "goodtag"} } }
      subject {
        CodeInclusion::FullListing::GitTag.new(args, FakeGitCmd.new).lines }

      it { should eq(["Real data", "second line"]) }
    end

    context "tag does not exist" do
      before(:all) do
        class FakeGitCmd < CodeInclusion::FullListing::GitTag::GitCmd
          def repository_exists?
            true
          end
          def tag_exists?
            false
          end
        end
      end

      let(:args) { { filename: "irreleventfile", git: {tag: "badtag"} } }
      subject { lambda {
        CodeInclusion::FullListing::GitTag.new(args, FakeGitCmd.new).lines } }

      it { should raise_exception(
            CodeInclusion::RetrievalException,
            "Tag 'badtag' does not exist."
            ) }
    end

    context "repo does not exist" do
      before(:all) do
        class FakeGitCmd < CodeInclusion::FullListing::GitTag::GitCmd
          def repository_exists?
            false
          end
        end
      end

      let(:args) { { filename: "irreleventfile", git: {repo: "baddir/.git"} } }
      subject { lambda {
        CodeInclusion::FullListing::GitTag.new(args, FakeGitCmd.new).lines } }

      it { should raise_exception(
            CodeInclusion::RetrievalException,
            "Repository 'baddir/.git' does not exist.") }
    end

    context "file does not exist" do
      before(:all) do
        class FakeGitCmd < CodeInclusion::FullListing::GitTag::GitCmd
          def show
            "fatal: Path 'badfile' does not exist in 'goodtag'"
          end
          def repository_exists?
            true
          end
          def tag_exists?
            true
          end
          def succeeded?
            false
          end
        end
      end

      let(:args) { { filename: "badfile",
                     git:      {tag: "goodtag"} } }
      subject { lambda {
        CodeInclusion::FullListing::GitTag.new(args, FakeGitCmd.new).lines } }

      it { should raise_exception(
            CodeInclusion::RetrievalException,
            "fatal: Path 'badfile' does not exist in 'goodtag'") }
    end

  end
end


describe "subset" do
  let(:input) {["line1",
                "line2",
                "#// begin sec_AAA",
                "line4",
                "line5",
                "#// end",
                "line7",
                "line8",
                "line9",
                "line10"]}

  describe "section" do

    context "exists" do
      let(:args) { {section: "sec_AAA"} }
      subject { CodeInclusion::Subset::Section.new(input, args).lines }

      it { should eq(["line4", "line5"]) }
    end

    context "does not exist" do
      let(:args) { {section: "missing section name"} }
      subject { lambda {CodeInclusion::Subset::Section.new(input, args).lines} }

      it { should raise_exception(CodeInclusion::SubsetException) }
    end
  end

  describe "line numbers" do
    let(:args) { {line_numbers: "1 , 2-1, 4- 5,10, 42"} }
    subject { CodeInclusion::Subset::LineNumber.new(input, args).lines }

    it { should eq(["line1", "line1", "line2", "line4", "line5", "line10"]) }
  end

  describe "everything" do
    subject { CodeInclusion::Subset::Everything.new(input).lines }

    it { should eq(input)}
  end
end
