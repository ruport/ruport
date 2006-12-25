module Ruport
  module Extensions
    class Invoice < Ruport::Renderer

      include Renderer::Helpers

      def init_options
        options do |o|
          o.customer_info ||= ""
          o.company_info  ||= ""
          o.comments      ||= ""
          o.order_info    ||= ""
          o.title         ||= ""
        end
      end
      
      def run
        init_options
        build [:headers,:body,:footer], :invoice
        finalize :invoice
      end

      module InvoiceHelpers
        def build_company_header
          @tod = pdf_writer.y
          text_box(options.company_info)
        end

        def build_customer_header
          pdf_writer.y -= 10
          text_box(options.customer_info)
        end

        def build_title
          pdf_writer.y = @tod
          if options.title
            pdf_writer.text options.title, :left => 350, 
            :font_size => layout.title_font_size || 14
            pdf_writer.y -= 10
          end
        end

        def build_order_header
          if options.order_info
            text_box(options.order_info, 
              :position => layout.order_info_position || 350)
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
          pdf_writer.y = 620

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

