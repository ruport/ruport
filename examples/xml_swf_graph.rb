require "ruport"

class XmlSwfGraph < Ruport::Report
  include Graph
  
  prepare do
    @table =  [ [  5,10,30,63 ],
                [300,20,65,55 ],
                [ 55,21, 5,90 ] ].to_table(%w[2001 2002 2003 2004])
    @table[0].tag "Region A"
    @table[1].tag "Region B"
    @table[2].tag "Region C"
  end

  generate do
    render_graph do |g|
      g.plugin = :xml_swf
      g.style  = :bar
      g.data   = @table
    end
  end
end

XmlSwfGraph.run { |r| puts r.results }
