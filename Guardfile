# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { "spec" }
  ## Uncomment & edit below (and comment out above) to watch particular specs.
  # watch(%r{^lib/(.+)\.rb$}) do
  #   [
  #     "spec/to_html/asides_spec.rb",
  #     "spec/to_html/codelistings_spec.rb"
  #   ]
  # end
  watch('spec/spec_helper.rb')  { "spec" }
end
