require "ruport"

class TitledPDFTable < Ruport::Format::PDF

  Ruport::Renderer::Table.add_format self, :titled_pdf
  
  def add_title( title )  
    rounded_text_box("<b>#{title}</b>") do |o|
      o.fill_color = Color::RGB::Gray80
      o.radius    = 5  
      o.width     = layout.header_width || 200
      o.height    = layout.header_height || 20
      o.font_size = layout.header_font_size || 12
      o.x         = pdf_writer.absolute_right_margin - o.width 
      o.y         = pdf_writer.absolute_top_margin
    end
  end      

  def prepare_table
    layout.header_margin ||= 50
  end

  def build_table_header
    add_title options.title
    move_cursor -layout.header_margin 
  end

end


a = Ruport::Renderer::Table.render_titled_pdf { |r|
  r.options.title = "This is a sample header"
  r.data = Table(%w[a b]) { |t| t << [1,2] << [3,4] }
  # NOTE: uncomment some options to play with layout
  r.layout do |la|
  #  la.header_margin = 25
  #  la.header_width = 250
  #  la.header_height = 50
  end
}

puts a
