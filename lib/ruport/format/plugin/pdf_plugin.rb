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
      
      renderer(:invoice) { pdf.render }

      # Company Information in top lefthand corner
      helper(:build_company_header, :engine => :invoice_engine) { |eng| 
        @tod = pdf.y
        text_box(eng.company_info)
      }

      helper(:build_headers, :engine => :invoice_engine) { |eng|
        build_company_header_helper(eng)
        build_customer_header_helper(eng)
        build_title_helper(eng)
        build_order_header_helper(eng)
      }

      helper(:build_order_header, :engine => :invoice_engine) { |eng|
        if eng.order_info
          text_box(eng.order_info, :position => 350)
        end
      }

      helper(:build_title, :engine => :invoice_engine) { |eng|
        pdf.y = @tod
        if eng.title
          pdf.text eng.title, :left => 350, :font_size => 14
          pdf.y -= 10
        end
      }

      helper(:build_footer, :engine => :invoice_engine) { |eng|
        # footer
        pdf.open_object do |footer|
          pdf.save_state
          pdf.stroke_color! Color::RGB::Black
          pdf.stroke_style! PDF::Writer::StrokeStyle::DEFAULT
          if eng.comments  
            pdf.y -= 20
            text_box eng.comments, :position => 110, :width => 400, 
                                   :font_size => 14
          end
          pdf.add_text_wrap( 50, 20, 200, "Printed at " + 
                             Time.now.strftime("%H:%M %d/%m/%Y"), 8)

          pdf.restore_state
          pdf.close_object
          pdf.add_object(footer, :all_pages)
        end
        pdf.stop_page_numbering(true, :current)
      } 
       
      helper(:build_body, :engine => :invoice_engine) do
       pdf.start_page_numbering(500, 20, 8, :right)
       
        # order contents 
        pdf.y = 620
        
        PDF::SimpleTable.new do |table|
          table.width = 450
          table.orientation = :center
          table.data = data
          table.show_lines = :outer
          table.column_order = data.column_names
          table.render_on(pdf)
          table.font_size = 12
        end
      end

      # Order details
      helper(:build_customer_header, :engine => :invoice_engine) { |eng| 
        pdf.y -= 10
        text_box(eng.customer_info)
      }
     
      def self.text_box(content,options={})
        PDF::SimpleTable.new do |table| 
          table.data = content.to_a.inject([]) do |s,line|
            s << { "value" => line }
          end
          table.column_order = "value"
          table.show_headings = false
          table.show_lines  = :outer
          table.shade_rows  = :none
          table.width       = options[:width] || 200
          table.orientation = options[:orientation] || :right
          table.position = options[:position] || :left
          table.font_size = options[:font_size] || 10
          table.render_on(pdf)
        end
      end
       
      plugin_name :pdf
      register_on :table_engine
      register_on :invoice_engine     
    end
  end
end

