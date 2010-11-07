require 'rake'
require 'rake/testtask'
#require 'rake/clean'

$: << 'lib'

task :default => :test

desc "Run the tests"
Rake::TestTask::new do |t|
    t.test_files = FileList['test/test_*.rb']
    t.verbose = true
end

