require "rubygems"
require "ruport"

class RoadmapRenderer < Ruport::Renderer

  option :image_file

  stage :roadmap_image, :roadmap_text_body
  finalize :roadmap

end

class HTMLRoadmap < Ruport::Formatter

  renders :html, :for => RoadmapRenderer
  opt_reader :image_file

  def layout
     output << "<html><body>\n"
     yield
     output << "</body></html>\n"
  end

  def build_roadmap_image
    output << "<img src='#{image_file}'/>"
  end
                                  
  def build_roadmap_text_body
    output << "<h2>This is a sample HTML report w. PDF</h2>"
  end
  
end

class PDFRoadmap < Ruport::Formatter::PDF

  renders :pdf, :for => RoadmapRenderer
  opt_reader :image_file

  def build_roadmap_image
    center_image_in_box image_file, :x => 0, :y => 200, 
                                   :width => 624, :height => 432
    move_cursor_to 80
  end

  def build_roadmap_text_body
    draw_text "This is a sample PDF with embedded PNG", :font_size => 16,
                                                        :x1 => 150
  end

  def finalize_roadmap
    render_pdf
  end

end

formats = [:html, :pdf]
formats.each do  |format|
  File.open("roadmap.#{format}","w") { |f|
     RoadmapRenderer.render format, :io => f, :image_file => "roadmap.png"
   }
end