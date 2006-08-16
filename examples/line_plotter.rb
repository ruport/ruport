require "ruport"

include Ruport

class LinePlotter < Format::Engine
  
  Line = Struct.new(:x1,:y1,:x2,:y2)
  
  renderer do
    active_plugin.data = get_lines
    active_plugin.render_plot
  end

  def self.get_lines
    data.map { |r| Line.new(r[0][0],r[0][1],r[1][0],r[1][1]) }
  end
  
  alias_engine LinePlotter, :line_plotting_engine
  Format.build_interface_for LinePlotter, :plot
end

class SVG < Format::Plugin

  renderer :plot do
    h = '<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">'+
        '<g stroke="black" stroke-width="1">'
    
    data.inject(h) { |s,r|
      s << "<line x1=\"#{r.x1}\" y1=\"#{r.y1}\"" <<
           " x2=\"#{r.x2}\" y2=\"#{r.y2}\" />"
    } << "</g></svg>"
  end
 
  register_on :line_plotting_engine
end

lines = [ [    [0,0],   [0,100] ], 
          [  [0,100], [100,100] ], 
          [ [100,100],  [100,0] ],
          [   [100,0],    [0,0] ] ]

a = Format.plot :plugin => :svg,
                :data => lines 
puts a
