require "ruport"
table = Table(%w[jan feb mar apr may jun jul]) do |t|
  t << [5,7,9,12,14,16,18]
  t << [21,3,8,19,13,15,1]
end

table[0].tag :ghosts
table[1].tag "pirates"

results = Ruport::Renderer::Graph.
  render_svg( :width => 700, :height => 500, :style => :line,
              :title => "Simple Line Graph" ) { |r| r.data = table }

File.open("line_graph.svg","w") { |f| f << results }

PAGE = <<-END_HTML
<html>
  <body>
  <embed
  src="line_graph.svg"
  width="700"
  height="500"
  />
</body>
<html>
END_HTML

File.open("line_graph.html","w") { |f| f << PAGE }
