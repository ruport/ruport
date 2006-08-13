$: << File.dirname(__FILE__) + "/../lib/"
require "ruport"

# Start with a Ruport::Table object. This could easily come from
# activerecord or any of the other ways to build a Table. See the ruport
# recipes book for some ideas
data = [[14.2, 14.4, 14.56, 14.87, 15.23, 15.58, 15.79]].to_table(%w[45000 35000 20000 15000 5000 400 17])

# initialize the graph with our table object
graph = Ruport::Format.graph_object :plugin => :svg, :data => data

# The SVG:Graph library accepts a wide range of options to style the resulting graph.
# These are set using a simple hash. The ones used below are approximately 1/3 of the available
# options.
options = {
  :graph_style => :line,
  :height => 500,
  :width  => 600,
  :graph_title => "Global Average Temperature vs. Number of Pirates",
  :show_graph_title => true,
  :x_title => "Number of Pirates (approx.)",
  :show_x_title => true,
  :y_title => "Global Average Temperature (C)",
  :show_y_title => true,
  :key => false,
  :min_scale_value => 13,
  :scale_integers => true,
  :no_css => true
}

# apply the options to the graph
graph.options = options

# render the graph and print it to stdout. To save the output to a file, try:
# ruby line_graph.rb > pirates.svg
puts graph.render
