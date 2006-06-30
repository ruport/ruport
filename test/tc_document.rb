require "test/unit"
require "ruport"

class TestDocument < Test::Unit::TestCase

  include Ruport
  
  def setup
    @empty_doc = Format::Document.new :test_doc1
    many_pages = [:p1,:p2,:p3,:p4].map { |p| Format::Page.new(p) }
    @populated_doc = Format::Document.new :test_doc2, :pages => many_pages
  end

  def test_basics
    assert_equal(:test_doc1,@empty_doc.name)
    assert_equal(:test_doc2,@populated_doc.name)
    assert_equal([],@empty_doc.pages)
    assert_equal([:p1,:p2,:p3,:p4],@populated_doc.pages.map { |p| p.name })
  end

  def test_each
    page_names = [:p1,:p2,:p3,:p4]
    
    @populated_doc.each { |p| assert_equal(page_names.shift,p.name) } 
    assert_equal([],page_names)
    
    @populated_doc.pages << Format::Page.new(:p5)
    page_names = [:p1,:p2,:p3,:p4,:p5]
    
    @populated_doc.each { |p| assert_equal(page_names.shift,p.name) }
    assert_equal([],page_names)
  end

  def test_add_page
    @empty_doc.add_page :p1
    @populated_doc.add_page :p5, :some_trait => "cool"
    assert(@empty_doc.find { |p| p.name.eql?(:p1) })
    assert(@populated_doc.find { |p| p.name.eql?(:p5) and 
                                     p.some_trait.eql?("cool") })
  end

end
