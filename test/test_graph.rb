require 'rubygems' rescue LoadError nil
require "test/unit"

class TestGraph < Test::Unit::TestCase

  def setup
    @data = [[1,2,3,2],[3,4,5,6]].to_table(%w[a b c d])
    @data_mismatched_headings = [[3,2],[3,4]].to_table(%w[a b c])
    @data_float = [[1.3,2],[3.28322,4]].to_table(%w[a b])
    @data_not_numbers = [["d",:sdfs,"not a number","1"],[3,4,5,6]].to_table(%w[a b c d])
  end

  # basic test to ensure bar charts render
  def test_bar
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :bar}
    output = graph.render

    assert_not_equal nil, output
  end

  # basic test to ensure horizontal pie charts render
  def test_bar_horizontal
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :bar_horizontal}
    output = graph.render

    assert_not_equal nil, output
  end
  
  # basic test to ensure line charts render
  def test_line
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :line}
    output = graph.render

    assert_not_equal nil, output
  end
  
  # basic test to ensure pie charts render
  def test_pie
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :pie}
    output = graph.render

    assert_not_equal nil, output
  end
 
  # ensure an exception is raised if the user doesn't name every column
  def test_mismatched_headings
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_mismatched_headings
    graph.options = {:graph_style => :line}

    assert_raises(ArgumentError) {
      output = graph.render
    }
  end
  
  # test to ensure floats can be graphed
  def test_floats
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_float
    graph.options = {:graph_style => :line}
    output = graph.render

    assert_not_equal nil, output
  end
  
  # ensure an exception is raised if non numeric data is graphed
  def test_not_numbers
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_not_numbers
    graph.options = {:graph_style => :line}
    
    assert_raises(ArgumentError) {
      output = graph.render
    }
  end

  # ensure an exception is raised if user tries to render a graph without setting any options
  def test_no_options
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    
    assert_raises(RuntimeError) {
      output = graph.render
    }

  end
  
  # test to make sure user requested options are applied to the resulting graph
  def test_options_applied_to_rendered_graph
    graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
    graph.options = {:graph_style => :line, :graph_title => 'Test', :show_graph_title => true, :no_css => true}
    output = graph.render
    
    # ensure the requested graph title is included in the SVG output. If that's there, we can
    # assume the rest are as well
    assert_not_equal nil, output[/class='mainTitle'/]

  end

end
