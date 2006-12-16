module Ruport::Format
  class PDF < Plugin
    attr_accessor :pdf_object
    attr_accessor :table_header_proc
    attr_accessor :table_footer_proc

    def prepare_table
      require "pdf/writer"
      require "pdf/simpletable"

      self.pdf_object ||= 
        ::PDF::Writer.new( :paper => layout.paper_size || "LETTER" )
    end

    def build_table_header
       table_header_proc[pdf_object] if table_header_proc
    end

    def build_table_body
      draw_table
    end

    def build_table_footer
      table_footer_proc[pdf_object] if table_footer_proc
    end

    def finalize_table
      output << pdf_object.render
    end

    def draw_table
      m = "Sorry, cant build PDFs from array like things (yet)"
      raise m if data.column_names.empty?
      ::PDF::SimpleTable.new do |table|
        table.maximum_width = layout.max_table_width || 500
        table.width         = layout.table_width if layout.table_width
        table.orientation   = layout.orientation || :center
        table.data          = data
        table.column_order  = data.column_names
        table.render_on(pdf_object)
      end
    end


  end
end
