require "ruport"                             

class Document < Ruport::Renderer
   
  def text=(other) 
    options.text = other  
  end     
                            
  def author=(other)
    options.author = other
  end
  
  def run
    plugin do 
      build_document_body 
      finalize
    end
  end
   
end


class CenteredPDFTextBox < Ruport::Format::PDF

  Document.add_format self, :pdf

  def build_document_body
    
    rounded_text_box(options.text) do |o|
       o.radius = 5
       o.width     = layout.width  || 400
       o.height    = layout.height || 110
       o.font_size = layout.font_size || 12
       
       o.x = pdf_writer.absolute_x_middle - o.width/2
       o.y = 600
    end         
    
    pad(10) do
      add_text "-- " << options.author << " --",
               :justification => :center, :font_size => 20 
    end
     
  end
  
  def finalize
    output << pdf_writer.render
  end
end

a = Document.render_pdf { |r|
  r.author = "Ralph Waldo Emerson"
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
