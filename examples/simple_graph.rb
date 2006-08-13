require "ruport"
data = [[1,4,7,9]].to_table(%w[a b c d])
data[0].tag "snickelfritz"
graph = Ruport::Format.graph_object :plugin => :svg, 
        :data => data
graph.options = {:graph_style => :line}
puts graph.render

