$: << File.join(File.dirname(__FILE__), '..', 'lib')
require "ruport"

class Document < Ruport::Controller
  stage :title, :body

  def setup
    self.data = Ruport::Data::Table.load('data/wine.csv')
  end
end

class DocumentFormatter < Ruport::Formatter::PrawnPDF
  renders :prawn_pdf, :for => Document

  def build_title
    pad(10) do
      text 'Wine', :style => :bold, :size => 20
    end
  end

  def build_body
    draw_table(data)
  end
end

Document.render(:prawn_pdf, :file => 'pdf_table_from_csv.pdf')
