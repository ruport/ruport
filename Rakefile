require "rake/rdoctask"
require "rake/testtask"
require "lib/ruport/version"

begin
  require "rubygems"
rescue LoadError
  nil
end

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir[ "test/*_test.rb" ]
  test.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'ruport'
    gemspec.rubyforge_project = 'ruport'
    gemspec.version = Ruport::VERSION
    gemspec.summary = 'A generalized Ruby report generation and templating engine.'
    gemspec.description = <<-END_DESC
      Ruby Reports is a software library that aims to make the task of reporting
      less tedious and painful. It provides tools for data acquisition,
      database interaction, formatting, and parsing/munging.
    END_DESC
    gemspec.email = 'gregory.t.brown@gmail.com'
    gemspec.homepage = 'http://rubyreports.org'
    gemspec.authors = ['Gregory Brown', 'Mike Milner', 'Andrew France']
    gemspec.rdoc_options = ['--title', 'Ruport Documentation', '--main', 'README', '-q']
    gemspec.add_dependency 'fastercsv'
    gemspec.add_dependency 'pdf-writer', '= 1.1.8'
  end
rescue LoadError
  puts "Jeweler gem not available."
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include( "README",
                           #"CHANGELOG",
                           "AUTHORS", "COPYING",
                           "LICENSE", "lib/" )
  rdoc.main     = "README"
  rdoc.rdoc_dir = "doc/html"
  rdoc.title    = "Ruport Documentation"
end

task :build_archives => [:package,:rcov,:rdoc] do
  mv "pkg/ruport-#{Ruport::VERSION}.tgz", "pkg/ruport-#{Ruport::VERSION}.tar.gz"
  sh "tar cjvf pkg/ruport_coverage-#{Ruport::VERSION}.tar.bz2 coverage"
  sh "tar cjvf pkg/ruport_doc-#{Ruport::VERSION}.tar.bz2 doc/html"
  cd "pkg"
  sh "tar cjvf ruport-#{Ruport::VERSION}.tar.bz2 ruport-#{Ruport::VERSION}"
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
