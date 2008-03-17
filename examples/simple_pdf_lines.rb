require "ruport"

# draws pretty little lines all over the place on a PDF

class SimpleLines < Ruport::Controller
  stage :horizontal_lines
end

class PDFLines < Ruport::Formatter::PDF
  renders :pdf, :for => SimpleLines

  def build_horizontal_lines
    data.each do |points|
      pad(10) { horizontal_line(*points) }
    end
    render_pdf
  end
end

# generate 35 random lines
data = (0..34).inject([]) { |s,r|
  s << [rand(100),100+rand(400)]
}

puts SimpleLines.render_pdf(:data => data)
