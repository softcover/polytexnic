# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  %w[foo bar].each do |filename|
    it "should correctly process #{filename}" do
      expect(polytex(filename)).to eql(html(filename))
    end
  end

  def polytex(filename)
    filename
  end

  def html(filename)
    filename
  end
end