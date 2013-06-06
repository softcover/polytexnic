# encoding=utf-8
require 'spec_helper'

describe String do
  let(:string) { "foo\t    bar\n\nbaz    quux\nderp" }
  let(:compressed_string) { "foo bar baz quux derp" }
  subject { string }

  it { should respond_to(:compress) }

  describe '#compress' do
    subject { string.compress }
    it { should eq compressed_string }
  end
end

describe "custom 'resemble' matcher" do

  it "should pass if two strings agree up to whitespace" do
    expect("foo      bar").to resemble " foo   \t\tbar "
  end

  it "should work for regexes" do
    expect("foo 628_tau bar").to resemble /foo \d+\w*        bar/
  end

  it "should work if the actual string contains the right substring" do
    expect("baz quux foo      bar derp").to resemble " foo   \t\tbar "
  end

  it "should work with backslashes" do
    expect('\emph{foo bar}').to resemble '\emph{foo bar}'
  end

  let(:nbsp) { ' ' }

  it "should work with Unicode nonbreak spaces" do
    expect('foo' + nbsp + nbsp + 'bar').to resemble 'foo bar'
  end

  it "should work with a mix of characters and codes" do
    expect('“foo bar&#8221;').to resemble '&#8220;foo bar”'
  end

  it "should work with multiline strings" do
    foo = <<-'EOS'
  <ul>
    <li>alpha</li>
    <li>bravo</li>
    <li>charlie</li>
  </ul>
    EOS
    bar = <<-'EOS'
<ul>
<li>alpha</li>
<li>bravo</li>
<li>charlie</li>
</ul>
    EOS

    expect(foo).to resemble bar
  end

  it "should handle HTML fragments identical up to whitespace" do
    foo = "<em>    foobar\n</em>"
    bar = "<em>foobar</em>"
    expect(foo).to resemble bar
  end
end
