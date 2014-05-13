# encoding=utf-8
require 'spec_helper'

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
          def show(_, _)
            "Real data\nsecond line"
          end
          def tag_exists?(tagname)
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
          def tag_exists?(tagname)
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

    context "file does not exist" do
      before(:all) do
        class FakeGitCmd < CodeInclusion::FullListing::GitTag::GitCmd
          def show(filename, tag)
            "fatal: Path 'badfile' does not exist in 'goodtag'"
          end
          def tag_exists?(tagname)
            true
          end
          def succeeded?
            false
          end
        end
      end

      let(:args) { { filename: "badfile", git: {tag: "goodtag"} } }
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