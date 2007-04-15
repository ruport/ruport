require "ruport"                             

class Document < Ruport::Renderer
  
  required_option :text
  required_option :author
  option :heading

  stage :document_body
  finalize :document                            
end


class CenteredPDFTextBox < Ruport::Formatter::PDF

  renders :pdf, :for => Document

  def build_document_body
    add_text "-- " << options.author << " --",
             :justification => :center, :font_size => 20
    
    c = pdf_writer.absolute_x_middle - 239/2
    
    center_image_in_box("RWEmerson.jpg", :x => c, :y => 325,
      :width => 239, :height => 359)
 
    rounded_text_box(options.text) do |o|
       o.radius = 5
       o.width     = options.width  || 400
       o.height    = options.height || 130
       o.font_size = options.font_size || 12
       o.heading   = options.heading
       
       o.x = pdf_writer.absolute_x_middle - o.width/2
       o.y = 300
    end
  end
  
  def finalize_document
    render_pdf
  end
end

a = Document.render_pdf( :heading => "a good quote", 
                         :author => "Ralph Waldo Emerson") { |r|
r.text = <<EOS
A foolish consistency is the hobgoblin of little minds, adored by little
statesmen and philosophers and divines. With consistency a great soul has simply
nothing to do. He may as well concern himself with his shadow on the wall. Speak
what you think now in hard words and to-morrow speak what to-morrow thinks in
hard words again, though it contradict every thing you said to-day.--"Ah, so you
shall be sure to be misunderstood."--Is it so bad then to be misunderstood?
Pythagoras was misunderstood, and Socrates, and Jesus, and Luther, and
Copernicus, and Galileo, and Newton, and every pure and wise spirit that ever
took flesh. To be great is to be misunderstood. . . .
EOS

}

puts a
