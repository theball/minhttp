require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

desc 'Test the mini_magick plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
