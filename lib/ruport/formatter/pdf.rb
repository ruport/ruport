module Ruport
   
  # PDF generation formatter
  #
  #  options:
  #     General:
  #       * paper_size  #=> "LETTER"
  #       * paper_orientation #=> :portrait
  #
  #     Text:
  #       * text_format
  #     
  #     Table:
  #       * table_format (a hash that can take any of the options available
  #           to PDF::SimpleTable)
  #       * table_format[:maximum_width] #=> 500
  #
  class Formatter::PDF < Formatter    
    
    renders :pdf, :for => [ Renderer::Row, Renderer::Table,
                            Renderer::Group, Renderer::Grouping ]
    
    attr_writer :pdf_writer
    attr_accessor :table_header_proc
    attr_accessor :table_footer_proc
    
    opt_reader  :show_table_headers,
                :style,
                :table_format,
                :text_format,
                :paper_size,
                :paper_orientation

    def initialize
      quiet do
        require "pdf/writer"
        require "pdf/simpletable"
      end
    end

    # Returns the current PDF::Writer object or creates a new one if it has not
    # been set yet.
    #
    def pdf_writer
      @pdf_writer ||= options.formatter ||
        ::PDF::Writer.new( :paper => paper_size || "LETTER",
              :orientation => paper_orientation || :portrait)
      @pdf_writer.extend(PDFWriterMemoryPatch)
    end

    # If table_header_proc is defined, it will be executed and the PDF::Writer
    # object will be yielded.
    #
    # This should be overridden by subclasses, or used as a shortcut for your
    # own plugin implementations
    #
    # This method is automatically called by the table renderer
    #
    def build_table_header
       table_header_proc[pdf_writer] if table_header_proc
    end

    # Calls the draw_table method
    #
    # This method is automatically called by the table renderer
    #
    def build_table_body
      draw_table(data)
    end

    def build_group_header
      pad(10) { add_text data.name.to_s, :justification => :center }
    end

    def build_group_body
      render_table data, options.to_hash.merge(:formatter => pdf_writer)
    end

    def build_grouping_body
      case(style)
      when :inline   
        data.each do |_,group|
          render_group group, options.to_hash.merge(:formatter => pdf_writer,
            :skip_finalize_table => true)
        end
      when :justified
        columns = data.data.to_a[0][1].column_names.dup.unshift(data.grouped_by)
        table = Ruport::Data::Table.new(:column_names => columns)
        data.each do |name,group|
          group_column = { data.grouped_by => "<b>#{name}</b>\n" }
          group.each_with_index do |rec,i|
            i == 0 ? table << group_column.merge(rec.to_h) : table << rec
          end
        end
        render_table table, options.to_hash.merge(:formatter => pdf_writer)
      when :offset
        columns = data.data.to_a[0][1].column_names.dup.unshift(data.grouped_by)
        table = Ruport::Data::Table.new(:column_names => columns)
        data.each do |name,group|
          table << ["<b>#{name}</b>\n",nil,nil]
          group.each {|r| table << r }
        end
        render_table table, options.to_hash.merge(:formatter => pdf_writer)
      when :separated
        columns = data.data.to_a[0][1].column_names.dup.unshift(data.grouped_by)
        table = Ruport::Data::Table.new(:column_names => columns)
        data.each do |name,group|
          group_column = { data.grouped_by => "<b>#{name}</b>\n" }
          group.each_with_index do |rec,i|
            i == 0 ? table << group_column.merge(rec.to_h) : table << rec
          end
          table << Array.new(columns.length,' ')
        end
        render_table table, options.to_hash.merge(:formatter => pdf_writer)
      else
        raise NotImplementedError, "Unknown style"
      end
    end
    
    def finalize_grouping
      output << pdf_writer.render
    end

    # If table_footer_proc is defined, it will be executed and the PDF::Writer
    # object will be yielded.
    #
    # This should be overridden by subclasses, or used as a shortcut for your
    # own plugin implementations
    #
    # This method is automatically called by the table renderer
    #
    def build_table_footer
      table_footer_proc[pdf_writer] if table_footer_proc
    end

    # Appends the results of PDF::Writer#render to output for your 
    # <tt>pdf_writer</tt> object.
    #
    def finalize_table
      output << pdf_writer.render unless options.skip_finalize_table
    end

    # Call PDF::Writer#text with the given arguments
    def add_text(text, format_opts={})
      format_opts = text_format.merge(format_opts) if text_format
      pdf_writer.text(text, format_opts)
    end

    # Calls PDF::Writer#render and appends to <tt>output</tt>
    def render_pdf
      output << pdf_writer.render
    end
       
    # - If the image is bigger than the box, it will be scaled down until
    #   it fits.
    # - If the image is smaller than the box, it won't be resized.
    #
    # options:
    # - :x: left bound of box
    # - :y: bottom bound of box
    # - :width: width of box
    # - :height: height of box
    #
    def center_image_in_box(path, image_opts={}) 
      x = image_opts[:x]
      y = image_opts[:y]
      width = image_opts[:width]
      height = image_opts[:height]
      info = ::PDF::Writer::Graphics::ImageInfo.new(File.read(path))

      # reduce the size of the image until it fits into the requested box
      img_width, img_height =
        fit_image_in_box(info.width,width,info.height,height)
      
      # if the width/height of the image is less than the requested box,
      # calculate the white space buffer
      x, y = add_white_space(x,y,img_width,width,img_height,height)

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
         add_text("<b>#{opts.heading}</b>", 
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
        center_image_in_box(imgpath, :x => x, :y => y,
          :width => width, :height => height)
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

    def pad_top(y,&block)
      move_cursor -y
      block.call
    end

    def pad_bottom(y,&block)
      block.call
      move_cursor -y
    end

    def draw_table(table_data, format_opts={})
      m = "Sorry, cant build PDFs from array like things (yet)"
      raise m if table_data.column_names.empty?
      
      format_opts = table_format.merge(format_opts) if table_format
      
      ::PDF::SimpleTable.new do |table|
        table.maximum_width = 500
        table.data          = table_data
        table.column_order  = table_data.column_names

        format_opts.each {|k,v| table.send("#{k}=", v) }

        table.render_on(pdf_writer)
      end
    end

    module DrawingHelpers

       def horizontal_line(x1,x2)
         pdf_writer.line(x1,cursor,x2,cursor)
         pdf_writer.stroke
       end

       def vertical_line_at(x,y1,y2)
         pdf_writer.line(x,y1,x,y2)
       end

       def left_boundary
         pdf_writer.absolute_left_margin
       end

       def right_boundary
         pdf_writer.absolute_right_margin
       end

       def top_boundary
         pdf_writer.absolute_top_margin
       end

       def bottom_boundary
         pdf_writer.absolute_bottom_margin
       end

       def cursor
          pdf_writer.y
       end

      # rather than being whimsical, let's be really F'in picky.
      def draw_text(text,draw_opts)
        move_cursor_to(y) if draw_opts[:y]
        add_text(text, draw_opts.merge( :absolute_left => 
                                         draw_opts[:x1] || draw_opts[:left],
                                         :absolute_right => 
                                         draw_opts[:x2]) || draw_opts[:right])
      end 

     end   

     include DrawingHelpers
     
     module PDFWriterMemoryPatch #:nodoc:
       unless self.class.instance_methods.include?("_post_transaction_rewind")
         def _post_transaction_rewind
            @objects.each { |e| e.instance_variable_set(:@parent,self) }
          end
       end
     end 
     
     private
     
     def image_fits_in_box?(img_width,box_width,img_height,box_height)
       !(img_width > box_width || img_height > box_height)
     end
     
     def fit_image_in_box(img_width,box_width,img_height,box_height)
       img_ratio = img_height.to_f / img_width.to_f
       until image_fits_in_box?(img_width,box_width,img_height,box_height)
         img_width -= 1
         img_height = img_width * img_ratio
       end
       return img_width, img_height
     end

     def add_white_space(x,y,img_width,box_width,img_height,box_height)
       if img_width < box_width
         white_space = box_width - img_width
         x = x + (white_space / 2)
       end
       if img_height < box_height
         white_space = box_height - img_height
         y = y + (white_space / 2)
       end
       return x, y
     end
     
  end
end


