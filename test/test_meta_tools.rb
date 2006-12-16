require "test/unit"
require "ruport"

class A; extend Ruport::MetaTools; end

class TestMetaTools < Test::Unit::TestCase
  
  def test_action
    assert_nothing_raised { A.action(:foo) { |x| x + 1 } }
    assert_equal 4, A.foo(3)
    assert_raise(ActionAlreadyDefinedError) { A.action(:foo) { } }
  end

  def test_attribute
    assert_nothing_raised { A.attribute :foo }
    assert_nothing_raised { A.foo = 3 }
    assert_equal 3, A.foo
    assert_raise(NoMethodError) { A.crack_rock }
  end

  def test_attribute
    assert_nothing_raised { A.attributes [:bar, :baz] }
    assert_nothing_raised { A.bar = 100 }
    assert_nothing_raised { A.baz = 200 }
    assert_equal [100,200], [A.bar,A.baz]
  end

end
