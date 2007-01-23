require "ruport"

class TitledPDFTable < Ruport::Format::PDF

  Ruport::Renderer::Table.add_format self, :titled_pdf

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
