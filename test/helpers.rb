require "test/unit"
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib') 
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end
require "spec-unit"
require "mocha"
require "stubba"

class Test::Unit::TestCase
  include SpecUnit
end