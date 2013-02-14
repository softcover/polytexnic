require 'spec_helper'

describe String do
  let(:string) { "foo\t    bar\n\nbaz    quux\nderp" }
  let(:compressed_string) { "foo bar\n\nbaz quux\nderp" }
  subject { string }

  it { should respond_to(:compress_whitespace) }
  it { should respond_to(:compress_whitespace!) }

  describe '#compress_whitespace' do
    subject { string.compress_whitespace }
    it { should eq(compressed_string) }
  end

  describe '#compress_whitespace!' do
    it "should replace the string with the string.compress_whitespace" do
      expect(string).not_to eq(compressed_string)
      string.compress_whitespace!
      expect(string).to eq(compressed_string)      
    end
  end
end

describe "custom 'resemble' matcher" do

  it "should pass if two strings agree up to whitespace" do
    expect("foo      bar").to resemble(" foo   \t\tbar ")
  end
  
  it "should work for regexes" do
    expect("foo 628_tau bar").to resemble(/foo \d+\w*        bar/)
  end
end
