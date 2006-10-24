module Ruport
  class Format::Plugin    
    class PDFPlugin < Format::Plugin
      attribute :pdf
      attribute :paper

      helper(:init_plugin) {
        require "pdf/writer"
        require "pdf/simpletable"
        self.pdf = PDF::Writer.new( :paper => paper || "LETTER" )
      }

      renderer :table do
        pre[pdf] if pre
        PDF::SimpleTable.new do |table|
          table.maximum_width = 500
          table.orientation = :center
          table.data = data
          m = "Sorry, cant build PDFs from array like things (yet)"      
          raise m if self.rendered_field_names.empty? 
          table.column_order = self.rendered_field_names
          table.render_on(pdf)
        end
        post[pdf] if post
        pdf.render
      end

      format_field_names { data.column_names }
      
      plugin_name :pdf
      register_on :table_engine
    end
  end
end

