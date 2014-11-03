
$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'ruport'
begin; require 'rubygems'; rescue LoadError; nil; end


require 'minitest'
require 'minitest/autorun'

require 'minitest/spec'
require 'minitest/unit'
require 'shoulda-context'
require 'mocha/mini_test'
class Minitest::Test
  include Ruport
end

TEST_SAMPLES = File.join(File.expand_path(File.dirname(__FILE__)), "samples")
