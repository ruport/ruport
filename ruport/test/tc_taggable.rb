#!/usr/local/bin/ruby -w

require "test/unit"
require "ruport"

class TestTaggable < Test::Unit::TestCase

  include Ruport::Data
  
  def setup
    @obj = Object.new.extend(Taggable)
  end
  
  def test_tags_are_empty_initially
    assert_equal [], @obj.instance_variable_get(:@ruport_tags)
  end
  
  def test_get_tags
    @obj.instance_variable_set(:@ruport_tags, [:blue, :red])
    assert_equal [:blue, :red], @obj.tags
  end
  
  def test_set_tags
    @obj.tags = [:orange, :yellow]
    assert_equal [:orange, :yellow], @obj.instance_variable_get(:@ruport_tags)
  end
  
  def test_tag
    @obj.tag(:purple)
    assert_equal [:purple], @obj.instance_variable_get(:@ruport_tags)
  end
  
  def test_has_tag
    @obj.tag(:maroon)
    assert @obj.has_tag?(:maroon)
  end
  
  def test_delete_tag
    @obj.tag(:scarlet)
    assert @obj.has_tag?(:scarlet)
    @obj.delete_tag(:scarlet)
    assert !@obj.has_tag?(:scarlet)
  end

  def test_avoid_duplication
    @obj.tag(:smelly)
    assert_equal 1, @obj.tags.select { |t| t.eql? :smelly }.length 
    @obj.tag(:smelly)
    assert_equal 1, @obj.tags.select { |t| t.eql? :smelly }.length   
  end
  
end
    
