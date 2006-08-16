require "ruport"
data = [[1,4,7,9]].to_table(%w[a b c d])
data[0].tag "snickelfritz"
g = Ruport::Format.graph_object(:plugin => :svg, :data => data)
g.options = { :graph_style => :line, 
               :graph_title => "Worms on Steriods", 
               :show_graph_title => true }

puts g.render
