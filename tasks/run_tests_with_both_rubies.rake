task default: [:rubies]

task :rubies do
  exit system('tasks/bin/ruby_tests')
end