require "test/unit"
require "ruport"

class TestSection < Test::Unit::TestCase
  include Ruport
  def setup
     elements = { :e1 =>  Format::Element.new(:e1), 
                  :e2 =>  Format::Element.new(:e2) }
     @empty_section     = Format::Section.new :test_section1
     @populated_section = Format::Section.new :test_section2, 
                                              :elements => elements
                                              
  end
  
  def test_basics
    assert_equal( :test_section1, @empty_section.name )
    assert_equal( :test_section2, @populated_section.name )
    assert_equal( [], [:e1,:e2]-@populated_section.map { |e| e.name } )
  end
  
  def test_each
    element_names = [:e1,:e2]
    @populated_section.each { |e| element_names -= [e.name] }
    assert_equal([],element_names)
    
    element_names = [:e1, :e2, :e3]
    @populated_section << Format::Element.new(:e3)
    @populated_section.each { |e| element_names -= [e.name] }
    assert_equal([],element_names)
  end

  def test_add_element
    @empty_section.add_element :e1
    @empty_section.add_element :e2, :content => "Hello from Element!"
    assert(@empty_section[:e1])
    assert(@empty_section[:e2])
    assert_equal("Hello from Element!",@empty_section[:e2].content)
  end

  def test_brackets
    assert_equal(:e1,@populated_section[:e1].name)
    assert_equal(:e2,@populated_section[:e2].name)
  end

end
