require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end
require "spec-unit"
require "mocha"
require "stubba"

class Test::Unit::TestCase
  include SpecUnit
end