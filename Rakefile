begin
  # Ruby 1.8.7 and below
  require "rake/rdoctask"
rescue LoadError
  # Ruby 1.9.2
  require "rdoc/task"
end
require "rake/testtask"
require "./lib/ruport/version"

begin
  require "rubygems"
rescue LoadError
  nil
end

require 'bundler/gem_tasks'

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir[ "test/*_test.rb" ]
  test.verbose = true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include( "README.rdoc",
                           "AUTHORS", "COPYING",
                           "LICENSE", "lib/" )
  rdoc.main     = "README.rdoc"
  rdoc.rdoc_dir = "doc/html"
  rdoc.title    = "Ruport Documentation"
end

task :run_benchmarks do
  files = FileList["util/bench/**/**/*.rb"]
  files.sort!
  files.uniq!
  names = files.map { |r| r.sub("util/bench","").split("/").map { |e| e.capitalize } }
  names.map! { |e| e[1..-2].join("::") + " <BENCH: #{e[-1].sub('Bench_','').sub('.rb','')}>" }
  start_time = Time.now
  files.zip(names).each { |f,n|
    puts "\n#{n}\n\n"
    sh "ruby -Ilib #{f}"
    puts "\n"
  }
  end_time = Time.now
  puts "\n** Total Run Time:  #{end_time-start_time}s **"
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = Dir[ "test/*_test.rb" ]
  end
rescue LoadError
  nil
end
