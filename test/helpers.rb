require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end
require "spec-unit"

class Test::Unit::TestCase
  include SpecUnit
end