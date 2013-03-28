task default: [:rubies]

task :rubies do
  exit system('bin/ruby_tests')
end