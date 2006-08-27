require "ruport"

begin; require 'rubygems'; rescue LoadError; nil; end
require "test/unit"

begin
  require 'scruffy'

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
      graph.title = "A Simple Bar Graph"
      graph.width = 600
      graph.height = 500
      graph.style = :bar
      output = graph.render

      assert_not_equal nil, output
    end

    # basic test to ensure line charts render
    def test_line
      graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
      graph.title = "A Simple Line Graph"
      graph.width = 600
      graph.height = 500
      graph.style = :line
      
      output = graph.render
      assert_not_equal nil, output
    end
   
    # ensure an exception is raised if the user doesn't name every column
    def test_mismatched_headings
      graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_mismatched_headings
      graph.title = "Mismatched Headings"
      graph.width = 600
      graph.height = 500
      graph.style = :line

      assert_raises(InvalidGraphDataError) {
        output = graph.render
      }
    end
    
    # test to ensure floats can be graphed
    def test_floats
      graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_float
      graph.title = "Graphing Floats"
      graph.width = 600
      graph.height = 500
      graph.style = :line
      output = graph.render

      assert_not_equal nil, output
    end
    
    # ensure an exception is raised if non numeric data is graphed
    def test_not_numbers
      graph = Ruport::Format.graph_object :plugin => :svg, :data => @data_not_numbers
      graph.title = "Graphing Things That Aren't Numbers"
      graph.width = 600
      graph.height = 500
      graph.style = :line
      
      assert_raises(InvalidGraphDataError) {
        output = graph.render
      }
    end

    # ensure an exception is raised if non numeric data is graphed
    def test_missing_required_option
      graph = Ruport::Format.graph_object :plugin => :svg, :data => @data
      graph.title = "Rendering a graph with a missing option"
      graph.height = 500
      graph.style = :line
      
      assert_raises(InvalidGraphOptionError) {
        output = graph.render
      }
   end
  end
rescue LoadError
  puts "Skipping Graph Tests (needs scruffy)"
end
