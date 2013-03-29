# encoding=utf-8
require 'spec_helper'

describe Polytexnic::Core::Pipeline do
  %w[inline_math verbatim_environments].each do |filename|
    it "should correctly process #{filename}" do
      expect(converted(filename)).to eql(html(filename))
    end
  end

  def converted(filename)
    Polytexnic::Core::Pipeline.new(contents(filename, 'tex')).process
  end

  def html(filename)
    contents(filename, 'html')
  end

  def contents(filename, extension)
    File.open(File.join('spec', 'fixtures', "#{filename}.#{extension}")).read
  end
end