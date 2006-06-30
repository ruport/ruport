require "test/unit"
require "ruport"

class TestElement < Test::Unit::TestCase
  include Ruport
  def setup
    @empty_element     = Format::Element.new :test_element
    @populated_element = Format::Element.new :test_element2, 
                                             :content => "Hello, Element!"
  end

  def test_basics
    assert_equal(:test_element,     @empty_element.name)
    assert_equal(:test_element2,    @populated_element.name)
    assert_equal("Hello, Element!", @populated_element.content)
  end

end
