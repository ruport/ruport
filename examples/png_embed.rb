require "rubygems"
require "ruport"

class RoadmapController < Ruport::Controller
  stage :roadmap_image, :roadmap_text_body
  finalize :roadmap
end

class HTMLRoadmap < Ruport::Formatter

  renders :html, :for => RoadmapController

  def layout
     output << "<html><body>\n"
     yield
     output << "</body></html>\n"
  end

  def build_roadmap_image
    output << "<img src='#{options.image_file}'/>"
  end
                                  
  def build_roadmap_text_body
    output << "<h2>This is a sample HTML report w. PDF</h2>"
  end
  
end

class PDFRoadmap < Ruport::Formatter::PDF

  renders :pdf, :for => RoadmapController

  def build_roadmap_image
    center_image_in_box options.image_file, :x => 0, :y => 200, 
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
  RoadmapController.render(format, :image_file => "roadmap.png", 
                                 :file => "roadmap.#{format}")
end
