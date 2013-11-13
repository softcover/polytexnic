# encoding=utf-8
require 'spec_helper'

# Returns a list of fixture filenames.
def filenames
  %w[inline_math verbatim_environments math_environments]
end

# Returns the results of converting the TeX filename to HTML.
def converted(filename)
  Polytexnic::Pipeline.new(contents(filename, 'tex')).to_html
end

# Returns the contents of the HTML filename fixture.
def html(filename)
  contents(filename, 'html')
end

# Returns the contents of a filename using its extension.
def contents(filename, extension)
  File.open(File.join('spec', 'fixtures', "#{filename}.#{extension}")).read
end

describe Polytexnic::Pipeline do

  filenames.each do |filename|
    it "should correctly process #{filename}" do
      tmp = 'tmp'
      File.mkdir(tmp) unless File.directory?(tmp)
      File.write(File.join(tmp, filename), converted(filename))
      expect(converted(filename)).to resemble html(filename)
    end
  end
end