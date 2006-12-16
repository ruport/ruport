require "ruport"

module MyStuff

  class DocumentRenderer < Ruport::Renderer
    include Ruport::Renderer::Helpers

    def run
      build [:header,:body,:footer],:document
      finalize :document
    end

    def table=(t)
      options.table = t
    end

    def header_text=(t)
      options.header_text=(t)
    end

    def footer_text=(t)
      options.footer_text=(t)
    end

  end

  class PDF < Ruport::Format::PDF
    DocumentRenderer.add_format self, :pdf

    def build_document_header
      add_text options.header_text, :justification => :center
    end

    def build_document_body
      pad(10) { draw_table }
    end

    def build_document_footer
      add_text options.footer_text, :justification => :center
    end

    def finalize_document
      output << pdf_writer.render
    end

  end
end

puts MyStuff::DocumentRenderer.render_pdf { |e| 
  e.data = [[1,2],[3,4]].to_table(%w[apple banana]) 
  e.header_text = "foo"
  e.footer_text = "bar"
}
