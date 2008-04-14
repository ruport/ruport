require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

RUPORT_VERSION = "1.6.1"

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

spec = Gem::Specification.new do |spec|
  spec.name = "ruport"
  spec.version = RUPORT_VERSION
  spec.platform = Gem::Platform::RUBY
  spec.summary = "A generalized Ruby report generation and templating engine."
  spec.files =  Dir.glob("{examples,lib,test,bin,util/bench}/**/**/*") +
                      ["Rakefile"]
  spec.require_path = "lib"
  
  spec.test_files = Dir[ "test/*_test.rb" ]
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README LICENSE AUTHORS}
  spec.rdoc_options << '--title' << 'Ruport Documentation' <<
                       '--main'  << 'README' << '-q'
  spec.add_dependency('fastercsv', '= 1.2.3')
  spec.add_dependency('pdf-writer','= 1.1.8')
  spec.author = "Gregory Brown"
  spec.email = "  gregory.t.brown@gmail.com"
  spec.rubyforge_project = "ruport"
  spec.homepage = "http://rubyreports.org"
  spec.description = <<END_DESC
  Ruby Reports is a software library that aims to make the task of reporting
  less tedious and painful. It provides tools for data acquisition,
  database interaction, formatting, and parsing/munging.
END_DESC
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

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :build_archives => [:package,:rcov,:rdoc] do
  mv "pkg/ruport-#{RUPORT_VERSION}.tgz", "pkg/ruport-#{RUPORT_VERSION}.tar.gz"
  sh "tar cjvf pkg/ruport_coverage-#{RUPORT_VERSION}.tar.bz2 coverage"
  sh "tar cjvf pkg/ruport_doc-#{RUPORT_VERSION}.tar.bz2 doc/html"
  cd "pkg"
  sh "tar cjvf ruport-#{RUPORT_VERSION}.tar.bz2 ruport-#{RUPORT_VERSION}"
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
