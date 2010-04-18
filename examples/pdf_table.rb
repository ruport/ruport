$: << File.join(File.dirname(__FILE__), '..', 'lib')
require "ruport"

# Example using prawn 0.9.0 pdf generator


class Document < Ruport::Controller
  stage :body

  def setup
    self.data = Ruport::Table(
      :column_names => %w(Make Model Year),
      :data => [
        %w(Nissan Skyline 1989),
        %w(Mercedes-Benz 500SL 2005),
        %w(Kia Sinatra 2008)
       ])
  end
end

class DocumentFormatter < Ruport::Formatter::PrawnPDF
  renders :prawn_pdf, :for => Document

  def build_body
    draw_table(data)
  end
end

Document.render(:prawn_pdf, :file => 'prawn_pdf.pdf')
