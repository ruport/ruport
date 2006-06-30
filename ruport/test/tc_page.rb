require "test/unit"
require "ruport"

class TestPage < Test::Unit::TestCase
  include Ruport
  def setup
    @empty_page = Format::Page.new :test_page1
    sections = { :s1 => Format::Section.new(:s1), :s2 => Format::Section.new(:s2) }
    @populated_page = Format::Page.new :test_page2, 
                                       :sections => sections
  end
  
  def test_basics
    assert_equal(:test_page1, @empty_page.name)
    assert_equal(:test_page2, @populated_page.name)
    assert_equal([],[:s1,:s2]-@populated_page.map { |s| s.name })
    assert_equal({},@empty_page.sections)
  end

  def test_each
    section_names = [:s1,:s2]
    @populated_page.each { |s| section_names -= [s.name] } 
    assert_equal([],section_names)
    @populated_page <<  Format::Section.new(:s3) 
    section_names = [:s1,:s2,:s3]
    @populated_page.each { |s| section_names -= [s.name] } 
    assert_equal([],section_names)
  end

  def test_add_function
    @populated_page.add_section :s3
    @populated_page.add_section :s4, :content => "Hello from Section!"
    assert(@populated_page.find { |s| s.name.eql?(:s3) })
    assert(@populated_page.find { |s| s.name.eql?(:s4) and
                                      s.content.eql?("Hello from Section!")} )
 
  end
  def test_brackets
    assert_equal(:s1,@populated_page[:s1].name)
    assert_equal(:s2,@populated_page[:s2].name)
  end
end
