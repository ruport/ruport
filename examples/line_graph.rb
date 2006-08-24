$: << File.dirname(__FILE__) + "/../lib/"
require "ruport"

# Start with a Ruport::Table object. This could easily come from
# activerecord or any of the other ways to build a Table. See the ruport
# recipes book for some ideas
data = [[5, 7, 9, 12, 14, 16, 18]].to_table(%w[jan feb mar apr may jun jul])

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
