require "ruport"

class LinePlotter < Ruport::Renderer

  layout do |l|
    l.line_color   = "green"
    l.line_width   = 2
    l.width        = "100%"
    l.height       = "100%"
  end

  def run
    plugin do |p|
      p.data = get_lines
      p.render_plot
    end
  end

  Line = Struct.new(:x1,:y1,:x2,:y2)

  def get_lines
    data.map { |r| Line.new( r[0][0],r[0][1],r[1][0],r[1][1] ) }
  end

end

class SVG < Ruport::Format::Plugin

  def initialize
    require "builder"
     @builder = Builder::XmlMarkup.new(:indent => 2)
  end

  def render_plot

    opts = { :width => layout.width, :height => layout.height,
             :xmlns => "http://www.w3.org/2000/svg" }

    output << @builder.svg(opts) do |builder|
      builder.g( :stroke        => layout.line_color,
                 "stroke-width" => layout.line_width ) do |g|
        data.each { |r| render_line(r,g) }
      end
    end

  end

  def render_line(line,xml_obj)
    opts = { :x1 => line.x1, :x2 => line.x2,
             :y1 => line.y1, :y2 => line.y2 }
    xml_obj.line(opts)
   end

  LinePlotter.add_format self, :svg

end

puts LinePlotter.render_svg { |r|
  r.data = [ [ [0,0],     [0,100]   ],
             [ [0,100],   [100,100] ],
             [ [100,100], [100,0]   ],
             [ [100,0],   [0,0]     ] ]
}
