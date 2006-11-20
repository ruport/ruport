module Ruport
  class Generator

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
    build_rakefile
    build_utils
  end

  def self.build_init
    File.open("#{project}/app/init.rb","w") { |f| f << INIT }
  end

  # Generates a trivial rakefile for use with Ruport.
  def self.build_rakefile
    File.open("#{project}/Rakefile","w") { |f| f << RAKEFILE }
  end

  # Generates the build.rb, sql_exec.rb, and cabinet.rb utilities
  def self.build_utils
    File.open("#{project}/util/build.rb","w") { |f| f << BUILD }
    File.open("#{project}/util/sql_exec.rb","w") { |f| f << SQL_EXEC }
  end

  # sets up the basic directory layout for a Ruport application
  def self.build_directory_structure
    mkdir project
    %w[ test config output data app app/reports 
        templates sql log util].each do |d|
      mkdir "#{project}/#{d}"
    end

    touch("#{project}/app/reports.rb")
    touch("#{project}/app/helpers.rb")
  end

  # Builds a file called config/ruport_config.rb which stores a Ruport::Config
  # skeleton
  def self.build_config
    File.open("#{project}/config/ruport_config.rb","w") { |f| f << CONFIG }
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
