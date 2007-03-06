require "ruport"

class SimpleLines < Ruport::Renderer
  stage :horizontal_lines
end

class PDFLines < Ruport::Format::PDF
  renders :pdf, :for => SimpleLines

  def build_horizontal_lines
    data.each do |points|
      pad(10) { horizontal_line(*points) }
    end
    output << pdf_writer.render
  end
end

# generate 35 random lines
data = (0..34).inject([]) { |s,r|
  s << [rand(100),100+rand(400)]
}

puts SimpleLines.render_pdf(:data => data)
