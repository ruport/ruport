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
       
    # - if the image is bigger than the box, it will be scaled down until it fits
    # - if the image is smaller than the box it's won't be resized
    #
    # arguments:
    # - x: left bound of box
    # - y: bottom bound of box
    # - width: width of box
    # - height: height of box
    def center_image_in_box(path, x, y, width, height)
      info = ::PDF::Writer::Graphics::ImageInfo.new(File.read(path))

      # if the image is larger than the requested box, prepare to
      # scale it down
      fits = !(info.width > width || info.height > height)

      # setup initial sizes for the image. These will be reduced as necesary
      img_width = info.width
      img_height = info.height
      img_ratio = info.height.to_f / info.width.to_f

      # reduce the size of the image until it fits into the requested box
      until fits
        img_width -= 1
        img_height = img_width * img_ratio
        fits = true if img_width < width && img_height < height
      end

      # if the width of the image is less than the requested box, calculate
      # the white space buffer
      if img_width < width
        white_space = width - img_width
        x = x + (white_space / 2)
      end

      # if the height of the image is less than the requested box, calculate
      # the white space buffer
      if img_height < height
        white_space = height - img_height
        y = y + (white_space / 2)
      end

      pdf_writer.add_image_from_file(path, x, y, img_width, img_height) 
    end

    # Draws some text on the canvas, surrounded by a box with rounded corners
    #
    def rounded_text_box(text)
       opts = OpenStruct.new
       yield(opts)
       
       # resize the text automatically to ensure it isn't wider than the box
       loop do
         sz = pdf_writer.text_width( text, opts.font_size )
         opts.x + sz > opts.x + opts.width or break
         opts.font_size -= 1
       end

       # save the drawing state (colors, etc) so we can restore it later
       pdf_writer.save_state

       # draw our box
       pdf_writer.fill_color(opts.fill_color || Color::RGB::White)
       pdf_writer.stroke_color(opts.stroke_color || Color::RGB::Black)
       pdf_writer.rounded_rectangle( opts.x, opts.y, 
                                     opts.width, opts.height, 
                                     opts.radius).fill_stroke

       # if a heading for this box has been specified
       if opts.heading
         pdf_writer.line( opts.x, opts.y - 20, 
                          opts.x + opts.width, opts.y - 20).stroke
         pdf_writer.fill_color(Color::RGB::Black)
         move_cursor_to(opts.y - 3)
         pdf_writer.text("<b>#{opts.heading}</b>", 
           :absolute_left => opts.x, :absolute_right => opts.x + opts.width,
           :justification => :center, :font_size => opts.font_size)
       end

       # restore the original colors
       pdf_writer.restore_state

       # move our y cursor into position, write the text, then move the cursor
       # to be just below the box
       pdf_writer.y = opts.heading ? opts.y - 20 : opts.y

       add_text( text,  :absolute_left  => opts.x,
                        :absolute_right => opts.x + opts.width,
                        :justification => opts.justification || :center,
                        :font_size => opts.font_size )     

       pdf_writer.y = opts.y - opts.height
    end

    # adds an image to every page. The color and size won't be modified,
    # but it will be centered.
    #
    def watermark(imgpath)
      x = pdf_writer.absolute_left_margin
      y = pdf_writer.absolute_bottom_margin
      width = pdf_writer.absolute_right_margin - x
      height = pdf_writer.absolute_top_margin - y

      pdf_writer.open_object do |wm|
        pdf_writer.save_state
        center_image_in_box(imgpath, x, y, width, height)
        pdf_writer.restore_state
        pdf_writer.close_object
        pdf_writer.add_object(wm, :all_pages)
      end
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
