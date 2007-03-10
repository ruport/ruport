require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

begin
  require "rubygems"
rescue LoadError
  nil
end

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir[ "test/test_*.rb" ]
  test.verbose = true
end

spec = Gem::Specification.new do |spec|
  spec.name = "ruport"
  spec.version = "0.9.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "A generalized Ruby report generation and templating engine."
  spec.files =  Dir.glob("{examples,lib,test,bin}/**/**/*") +
                      ["Rakefile", "setup.rb"]
  
  spec.require_path = "lib"
  
  spec.test_files = Dir[ "test/test_*.rb" ]
  spec.bindir = "bin"
  spec.executables = FileList["rope"]
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README LICENSE TODO AUTHORS}
  spec.rdoc_options << '--title' << 'Ruport Documentation' <<
                       '--main'  << 'README' << '-q'
  spec.add_dependency('transaction-simple', "=1.4.0")
  spec.add_dependency('fastercsv', '>= 1.1.0')
  spec.add_dependency('RedCloth',  '>= 3.0.3')
  spec.add_dependency('pdf-writer', '>= 1.1.3')
  spec.add_dependency("mailfactory", ">= 1.2.3")
  spec.add_dependency('gem_plugin', '>=0.2.2')
  spec.author = "Gregory Brown"
  spec.email = "  gregory.t.brown@gmail.com"
  spec.rubyforge_project = "ruport"
  spec.homepage = "http://reporting.stonecode.org"
  spec.description = <<END_DESC
  Ruby Reports is a software library that aims to make the task of reporting
  less tedious and painful. It provides tools for data acquisition,
  database interaction, formatting, and parsing/munging.
END_DESC
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include( "README",
                           "TODO", #"CHANGELOG",
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

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = Dir[ "test/test_*.rb" ]
  end
rescue LoadError
  nil
end
