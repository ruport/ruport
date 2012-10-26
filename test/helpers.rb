require "test/unit"
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end
require "shoulda"
require "mocha"

class Test::Unit::TestCase
  include Ruport
end

TEST_SAMPLES = File.join(File.expand_path(File.dirname(__FILE__)), "samples")
