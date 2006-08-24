$: << File.dirname(__FILE__) + "/../lib/"
require "ruport"

# Start with a Ruport::Table object. This could easily come from
# activerecord or any of the other ways to build a Table. See the ruport
# recipes book for some ideas
data = [[14.2, 14.4, 14.56, 14.87, 15.23, 15.58, 15.79]].to_table(%w[45000 35000 20000 15000 5000 400 17])

# initialize the graph with our table object
graph = Ruport::Format.graph_object :plugin => :svg, :data => data

# there are currently only a handful of options for customising the 
# appearance of the graph. The ones listed here are all of them at
# the current time.
graph.width = 700
graph.height = 500
graph.title = "A Simple Line Graph"
graph.style = :line # other options: bar, smiles, area, stacked

# render the graph and print it to stdout. To save the output to a file, try:
# ruby line_graph.rb > pirates.svg
puts graph.render
