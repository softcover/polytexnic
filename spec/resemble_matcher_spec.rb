require 'spec_helper'

describe String do
  let(:string) { "foo\t    bar\n\nbaz    quux\nderp" }
  let(:compressed_string) { "foo bar\n\nbaz quux\nderp" }
  subject { string }

  it { should respond_to(:compress) }
  it { should respond_to(:compress!) }

  describe '#compress' do
    subject { string.compress }
    it { should eq(compressed_string) }
  end

  describe '#compress!' do
    it "should replace the string with the string.compress" do
      expect(string).not_to eq(compressed_string)
      string.compress!
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

  it "should work if the actual string contains the right substring" do
    expect("baz quux foo      bar derp").to resemble(" foo   \t\tbar ")    
  end
end
