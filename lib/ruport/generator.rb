module Ruport
  class Generator
  extend FileUtils

  begin
    require "rubygems"
  rescue LoadError
    nil
  end
  require "ruport"

  def self.build(proj)
    @project = proj
    build_directory_structure
    build_init
    build_config
    build_utils         
    build_rakefile  
    puts "\nSuccessfully generated project: #{proj}"
  end

  def self.build_init
    m = "#{project}/app/init.rb" 
    puts "  #{m}"
    File.open(m,"w") { |f| f << INIT }
  end

  # Generates a trivial rakefile for use with Ruport.
  def self.build_rakefile
    m = "#{project}/Rakefile"
    puts "  #{m}"
    File.open(m,"w") { |f| f << RAKEFILE }
  end

  # Generates the build.rb, sql_exec.rb, and cabinet.rb utilities
  def self.build_utils           
    
    m = "#{project}/util/build.rb"   
    puts "  #{m}"
    File.open(m,"w") { |f| f << BUILD } 
    
    m = "#{project}/util/sql_exec.rb"  
    puts "  #{m}"
    File.open(m,"w") { |f| f << SQL_EXEC }
  end

  # sets up the basic directory layout for a Ruport application
  def self.build_directory_structure
    mkdir project        
    puts "creating directories.."
    %w[ test config output data app app/reports 
        templates sql log util].each do |d|
      m="#{project}/#{d}" 
      puts "  #{m}"
      mkdir(m)
    end
    
    puts "creating files.."
    %w[reports helpers].each { |f|
      m = "#{project}/app/#{f}.rb"
      puts "  #{m}"
      touch(m)
    }
  end

  # Builds a file called config/ruport_config.rb which stores a Ruport::Config
  # skeleton
  def self.build_config
    m = "#{project}/config/ruport_config.rb"
    puts "  #{m}"
    File.open(m,"w") { |f| f << CONFIG }
  end

  # returns the project's name
  def self.project; @project; end

RAKEFILE = <<END_RAKEFILE
begin; require "rubygems"; rescue LoadError; end
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs    << "test"
  test.pattern =  'test/**/test_*.rb'
  test.verbose =  true
end
END_RAKEFILE

CONFIG = <<END_CONFIG
require "ruport"

# For details, see Ruport::Config documentation
Ruport.configure { |c|
  c.source :default, :user     => "root", 
                     :dsn      =>  "dbi:mysql:mydb"
  c.log_file "log/ruport.log"
}
END_CONFIG

BUILD = <<'END_BUILD'
require 'fileutils'
include FileUtils

def format_class_name(string)
  string.downcase.split("_").map { |s| s.capitalize }.join
end

unless ARGV.length > 1
  puts "usage build.rb [command] [options]"
  exit
end

class_name = format_class_name(ARGV[1])

exit if File.exist? "app/reports/#{ARGV[1]}.rb"
if ARGV[0].eql? "report"
  File.open("app/reports.rb", "a") { |f| 
    f.puts("require \"app/reports/#{ARGV[1]}\"")
  }
REP = <<EOR
require "app/init"
class #{class_name} < Ruport::Report
  
  def prepare

  end
 
  def generate

  end

  def cleanup

  end

end

if __FILE__ == $0
   #{class_name}.run { |res| puts res.results }
end
EOR

TEST = <<EOR
require "test/unit"
require "app/reports/#{ARGV[1]}"

class Test#{class_name} < Test::Unit::TestCase
  def test_flunk
    flunk "Write your real tests here or in any test/test_* file"
  end
end
EOR
  File.open("app/reports/#{ARGV[1]}.rb", "w") { |f| f << REP }
  File.open("test/test_#{ARGV[1]}.rb","w") { |f| f << TEST } 
end
END_BUILD

SQL_EXEC = <<'END_SQL'
require "app/init"

puts Ruport::Query.new(ARGF.read).result
END_SQL

INIT = <<END_INIT
begin
  require "rubygems"
  require_gem "ruport","=#{Ruport::VERSION}"
rescue LoadError 
  nil
end
require "ruport"
require "app/helpers"
require "config/ruport_config"
END_INIT

  end
end
