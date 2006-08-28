require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

begin
  require "rubygems"
rescue LoadError
  nil
end

#Set to true to disable dependency resolution
LEAN=false
dir = File.dirname(__FILE__)
lib = File.join(dir, "lib", "ruport.rb")
version = File.read(lib)[/^\s*VERSION\s*=\s*(['"])(\d+\.\d+\.d+)['"]/,1]
task :default => [:test]

Rake::TestTask.new do |test|
	test.libs << "test"
	test.test_files = Dir[ "test/test_*.rb" ]
	test.verbose = true
end

spec = Gem::Specification.new do |spec|
	spec.name = LEAN ? "lean-ruport" : "ruport"
	spec.version = "0.5.99"
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
  unless LEAN
    spec.add_dependency('fastercsv', '>= 0.1.0')
    spec.add_dependency('RedCloth',  '>= 3.0.0')
    spec.add_dependency('pdf-writer', '>= 1.1.3')
    spec.add_dependency("mailfactory", ">= 1.2.2")
    spec.add_dependency('scruffy', '>= 0.2.2')
  end
  spec.author = "Gregory Brown"
	spec.email = "	gregory.t.brown@gmail.com"
	spec.rubyforge_project = "ruport"
	spec.homepage = "http://reporting.stonecode.org"
	spec.description = <<END_DESC
Ruport is a powerful report generation engine that allows users to generate
custom ERb templates and easily query various forms of SQL databases via DBI.
It provides helper methods and utilities to generate professional reports
quickly and cleanly. 
END_DESC
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include( "README",
                           "TODO", "CHANGELOG",
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

desc "Generate Ruport Recipes. Assumes you have erb, redcloth, and htmldoc."
task :cookbook do
  sh "erb doc/ruport_recipes.textile | redcloth >doc/temp.html" 
  sh "htmldoc --batch doc/ruport.book" rescue nil
  rm "doc/temp.html"
  mv "out.pdf", "doc/out.pdf"
end
