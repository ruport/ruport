require 'rubygems' rescue LoadError nil
require "test/unit"

class TestGraph < Test::Unit::TestCase

  def setup
    @data = [[1,2,3,2],[3,4,5,6]].to_table(%w[a b c d])
    @data_mismatched_headings = [[3,2],[3,4]].to_table(%w[a b c])
    @data_float = [[1.3,2],[3.28322,4]].to_table(%w[a b])
    @data_not_numbers = [["d",:sdfs,"not a number","1"],[3,4,5,6]].to_table(%w[a b c d])
  end

  def test_bar
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :bar}
    output = graph.render

    assert_not_equal nil, output
  end

  def test_bar_horizontal
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :bar_horizontal}
    output = graph.render

    assert_not_equal nil, output
  end
  
  def test_line
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :line}
    output = graph.render

    assert_not_equal nil, output
  end
  
  def test_pie
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :pie}
    output = graph.render

    assert_not_equal nil, output
  end
 
  def test_mismatched_headings
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_mismatched_headings
    graph.options = {:graph_style => :line}

    assert_raises(ArgumentError) {
      output = graph.render
    }
  end
  
  def test_floats
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_float
    graph.options = {:graph_style => :line}
    output = graph.render

    assert_not_equal nil, output
  end
  
  def test_not_numbers
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_not_numbers
    graph.options = {:graph_style => :line}
    
    assert_raises(ArgumentError) {
      output = graph.render
    }
  end
end
