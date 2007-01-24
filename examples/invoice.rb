module Ruport
  module Extensions
    class Invoice < Ruport::Renderer

      include Renderer::Helpers
               
      required_option :customer_info
      required_option :company_info
      required_option :order_info
      option :title
      required_option :comments
      
      stage :invoice_headers
      stage :invoice_body
      stage :invoice_footer
      
      finalize :invoice

      module InvoiceHelpers
        def build_company_header
          @tod = pdf_writer.y
          text_box(options.company_info)
        end

        def build_customer_header
          move_cursor -10
          text_box(options.customer_info)
        end

        def build_title
          add_title(options.title) if options.title
        end
        
        def add_title( title )  
          rounded_text_box("<b>#{title}</b>") do |o|
            o.fill_color = Color::RGB::Gray80
            o.radius    = 5  
            o.width     = layout.header_width || 200
            o.height    = layout.header_height || 20
            o.font_size = layout.header_font_size || 11
            o.x         = pdf_writer.absolute_right_margin - o.width 
            o.y         = pdf_writer.absolute_top_margin
          end
        end      

        def build_order_header
          if options.order_info
            rounded_text_box("<b>#{options.order_info}</b>") do |o|
              o.radius    = 5  
              o.heading   = "Billing Information"
              o.width     = layout.header_width || 200
              o.height    = layout.header_height || 80
              o.font_size = layout.header_font_size || 10
              o.x         = pdf_writer.absolute_right_margin - o.width 
              o.y         = pdf_writer.absolute_top_margin - 25
            end 
          end
        end

        def text_box(content,opts={})
            ::PDF::SimpleTable.new do |table| 
            table.data = content.to_a.inject([]) do |s,line|
              s << { "value" => line, }
            end
            
            table.column_order = "value"
            table.show_headings = false
            table.show_lines  = :outer
            table.shade_rows  = :none
            table.width       = opts[:width] || 200
            table.orientation = opts[:orientation] || :right
            table.position = opts[:position] || :left
            table.font_size = opts[:font_size] || 10
            table.render_on(pdf_writer)
          end    
        end
      end
       
      class PDF < Ruport::Format::PDF
        
        include InvoiceHelpers
        Invoice.add_format self, :pdf

        def build_invoice_headers
          build_company_header
          build_customer_header
          build_title
          build_order_header
        end
        
        def build_invoice_body
         
          pdf_writer.start_page_numbering(500,20,8,:right)
          pdf_writer.y = 550

          Ruport::Renderer::Table.render_pdf { |r|
            r.data = data
            r.plugin.pdf_writer = pdf_writer
            r.layout.table_width = layout.body_width || 450
          }

        end

        def build_invoice_footer
         # footer
          pdf_writer.open_object do |footer|
            pdf_writer.save_state
            pdf_writer.stroke_color! Color::RGB::Black
            pdf_writer.stroke_style! ::PDF::Writer::StrokeStyle::DEFAULT
            if options.comments  
              pdf_writer.y -= 20
              text_box options.comments, 
                :position      => layout.comments_position    || 110, 
                :width         => layout.comments_width       || 400, 
                :font_size     => layout.comments_font_size   || 14, 
                :orientation   => layout.comments_orientation
            end
            pdf_writer.add_text_wrap( 50, 20, 200, "Generated at " + 
              Time.now.strftime(options.date_format || "%H:%M %Y-%m-%d"), 8)

            pdf_writer.restore_state
            pdf_writer.close_object
            pdf_writer.add_object(footer, :all_pages)
          end
          pdf_writer.stop_page_numbering(true, :current)
        end

        def finalize_invoice
          output << pdf_writer.render
        end

      end 
    end 
  end  
end

module Ruport::Report::Invoice
  def render_invoice(&block)
    Ruport::Extensions::Invoice.render_pdf(&block)
  end
end

