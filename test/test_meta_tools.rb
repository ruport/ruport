require "test/unit"
require "ruport"

class A; extend Ruport::MetaTools; end

class TestMetaTools < Test::Unit::TestCase
  
  def test_action
    assert_nothing_raised { A.action(:foo) { |x| x + 1 } }
    assert_equal 4, A.foo(3)
    assert_raise(ActionAlreadyDefinedError) { A.action(:foo) { } }
  end

end
