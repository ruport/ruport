require 'coveralls'
require 'simplecov'
require 'coveralls'

# Use this formatter instead if you want to see coverage locally:
#
# SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
#   SimpleCov::Formatter::HTMLFormatter,
#   Coveralls::SimpleCov::Formatter
# ])

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'test'
end

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'ruport'
require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/unit'
require 'shoulda-context'
require 'mocha/minitest'
class Minitest::Test
  include Ruport
end

TEST_SAMPLES = File.join(File.expand_path(File.dirname(__FILE__)), "samples")
