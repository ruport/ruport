
$: << File.join(File.dirname(__FILE__), '..', 'lib')
require "ruport"
require "ruby-debug"

class Document < Ruport::Controller
  stage :title, :body

  def setup
    table = Ruport::Data::Table.load('data/wine.csv')
    grouping = Grouping(table, :by => 'Type')
    self.data = grouping
  end
end

class DocumentFormatter < Ruport::Formatter::PrawnPDF
  renders :prawn_pdf, :for => Document

  def build_title
    pad(10) do
      text 'WINES', :style => :bold, :size => 20
      horizontal_rule
    end
  end

  def build_body
    render_grouping(data, :formatter => pdf) # It's Nasty!!!
  end
end

class DocumentTextFormatter < Ruport::Formatter::Text
  renders :text, :for => Document

  def build_body
    output << data.to_text
  end
end

Document.render(:prawn_pdf, :file => 'pdf_grouping.pdf')
