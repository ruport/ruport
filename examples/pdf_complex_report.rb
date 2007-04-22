require 'rubygems'
require "ruport"

module MyStuff

  class DocumentRenderer < Ruport::Renderer
    required_option :header_text, :footer_text

    stage :document_header, :document_body, :document_footer
    
    finalize :document
  end

  class PDF < Ruport::Formatter::PDF
    renders :pdf, :for => DocumentRenderer

    def build_document_header
      add_text options.header_text, :justification => :center
    end

    def build_document_body
      pad(10) { draw_table(data) }
    end

    def build_document_footer
      add_text options.footer_text, :justification => :center
    end

    def finalize_document
      render_pdf
    end
  end

end

puts MyStuff::DocumentRenderer.render_pdf { |e| 
  e.data = [[1,2],[3,4]].to_table(%w[apple banana]) 
  e.header_text = "foo"
  e.footer_text = "bar"
}
