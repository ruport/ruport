require "ruport"
graph = Ruport::Format.graph_object :plugin => :svg, 
        :data => [[1,4,7,9]].to_table(%w[a b c d])
graph.options = {:graph_style => :bar}
puts graph.render

