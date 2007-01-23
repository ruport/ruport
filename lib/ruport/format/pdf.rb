module Ruport::Format

  # PDF generation plugin
  #
  #  layout options:
  #     General:
  #       * paper_size  #=> "LETTER"
  #       * orientation #=> :center
  #     
  #     Table:
  #       * table_width
  #       * max_table_width #=> 500
  #
  class PDF < Plugin
    attr_writer :pdf_writer
    attr_accessor :table_header_proc
    attr_accessor :table_footer_proc

    def initialize
      require "pdf/writer"
      require "pdf/simpletable"
    end

    def pdf_writer
      @pdf_writer ||= 
        ::PDF::Writer.new( :paper => layout.paper_size || "LETTER" )
    end

    def build_table_header
       table_header_proc[pdf_writer] if table_header_proc
    end

    def build_table_body
      draw_table
    end

    def build_table_footer
      table_footer_proc[pdf_writer] if table_footer_proc
    end

    def finalize_table
      output << pdf_writer.render
    end

    def add_text(*args)
      pdf_writer.text(*args)
    end
    
    def add_title( title )  
      rounded_text_box("<b>#{title}</b>") do |o|
        o.radius    = 5  
        o.width     = layout.header_width || 200
        o.height    = layout.header_height || 20
        o.font_size = layout.header_font_size || 12
        o.x         = pdf_writer.absolute_right_margin - o.width 
        o.y         = pdf_writer.absolute_top_margin
      end
    end     
    
    def rounded_text_box(text)
       options = OpenStruct.new
       yield(options)
       
       width      = options.width 
       height     = options.height
       top_left_x = options.x
       top_left_y = options.y
       radius     = options.radius
       font_size  = options.font_size 
       
       loop do
         sz = pdf_writer.text_width( text, font_size )
         top_left_x + sz > top_left_x + width or break
         font_size -= 1
       end

       pdf_writer.fill_color(Color::RGB::Gray80)
       pdf_writer.rounded_rectangle( top_left_x, top_left_y, 
                                     width, height, radius).fill_stroke
       pdf_writer.fill_color(Color::RGB::Black)
       pdf_writer.stroke_color(Color::RGB::Black)     
       pdf_writer.y = top_left_y
       add_text( text,  :absolute_left  => top_left_x,
                        :absolute_right => top_left_x + width,
                        :justification => :center,
                        :font_size => font_size)     
    end

    def move_cursor(n) 
      pdf_writer.y += n
    end

    def move_cursor_to(n)
      pdf_writer.y = n
    end

    def pad(y,&block)
      move_cursor -y
      block.call
      move_cursor -y
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
        table.render_on(pdf_writer)
      end
    end


  end
end
