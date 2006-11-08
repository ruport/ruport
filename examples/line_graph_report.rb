require "ruport"
class GraphSample < Ruport::Report
  
  include Graph

  prepare do
    @data = table(%w[jan feb mar apr may jun jul]) do |t|
      t << [5,7,9,12,14,16,18]
    end
  end

  generate do
    render_graph do |g|
      g.data   = @data
      g.width  = 700
      g.height = 500
      g.title  = "A Simple Line Graph"
      g.style  = :line
    end
  end
end

GraphSample.run { |r| r.write "line_graph.svg" }


