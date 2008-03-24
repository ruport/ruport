# Ruport : Extensible Reporting System                                
#
# formatter/pdf.rb provides text formatting for Ruport.
#     
# Created by Gregory Brown, February 2006     
# Extended by James Healy, Fall 2006
# Copyright (C) 2006-2007 Gregory Brown / James Healy, All Rights Reserved.  
#
# Initially inspired by some ideas and code from Simon Claret,
# with many improvements from James Healy and Michael Milner over time.
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.   
#
module Ruport
   
  # This class provides PDF output for Ruport's Table, Group, and Grouping
  # controllers.  It wraps Austin Ziegler's PDF::Writer to provide a higher
  # level interface and provides a number of helpers designed to make
  # generating PDF reports much easier.  You will typically want to build
  # subclasses of this formatter to customize it as needed.
  #
  # Many methods forward options to PDF::Writer, so you may wish to consult
  # its API docs.
  #
  # === Rendering Options
  #     General:
  #       * paper_size  #=> "LETTER"
  #       * paper_orientation #=> :portrait
  #
  #     Text:
  #       * text_format (sets options to be passed to add_text by default)  
  #     
  #     Table:
  #       * table_format (a hash that can take any of the options available
  #           to PDF::SimpleTable)
  #       * table_format[:maximum_width] #=> 500   
  #
  #     Grouping:
  #       * style (:inline,:justified,:separated,:offset)
  #
  class Formatter::PDF < Formatter         

    module PDFWriterProxy #:nodoc:
      def method_missing(id,*args)
        super(id,*args)
      rescue
        pdf_writer.send(id,*args)
      end
    end
    
    renders :pdf, :for => [ Controller::Row, Controller::Table,
                            Controller::Group, Controller::Grouping ]
    
    attr_writer :pdf_writer


    # If you use this macro in your formatter, Ruport will automatically forward
    # calls to the underlying PDF::Writer, for any methods that are not wrapped
    # or redefined.
    def self.proxy_to_pdf_writer
      include PDFWriterProxy
    end

    save_as_binary_file

    def initialize
      Ruport.quiet do   
        require "pdf/writer"
        require "pdf/simpletable"
      end
    end
    
    # Hook for setting available options using a template. See the template 
    # documentation for the available options and their format.
    def apply_template
      apply_page_format_template(template.page)
      apply_text_format_template(template.text)
      apply_table_format_template(template.table)
      apply_column_format_template(template.column)
      apply_heading_format_template(template.heading)
      apply_grouping_format_template(template.grouping)
    end

    # Returns the current PDF::Writer object or creates a new one if it has not
    # been set yet.
    #    
    def pdf_writer
      @pdf_writer ||= options.formatter ||
        ::PDF::Writer.new( :paper => options.paper_size || "LETTER",
              :orientation => options.paper_orientation || :portrait)
    end

    # Calls the draw_table method.
    #
    def build_table_body
      draw_table(data)
    end

    # Appends the results of PDF::Writer#render to output for your 
    # <tt>pdf_writer</tt> object.
    #
    def finalize_table
      render_pdf unless options.skip_finalize_table
    end
    
    # Generates a header with the group name for Controller::Group.
    def build_group_header
      pad(10) { add_text data.name.to_s, :justification => :center }
    end
    
    # Renders the group as a table for Controller::Group.
    def build_group_body
      render_table data, options.to_hash.merge(:formatter => pdf_writer)
    end
                     
    # Determines which style to use and renders the main body for
    # Controller::Grouping.
    def build_grouping_body 
      case options.style
      when :inline
        render_inline_grouping(options.to_hash.merge(:formatter => pdf_writer,
            :skip_finalize_table => true))
      when :justified, :separated
        render_justified_or_separated_grouping
      when :offset
        render_offset_grouping
      else
        raise NotImplementedError, "Unknown style"
      end
    end
   
    # Calls <tt>render_pdf</tt>.
    def finalize_grouping
      render_pdf
    end

    # Call PDF::Writer#text with the given arguments, using
    # <tt>text_format</tt> defaults, if they are defined.                                       
    #
    # Example:
    #
    #   options.text_format { :font_size => 14 }
    #
    #   add_text("Hello Joe") #renders at 14pt
    #   add_text("Hello Mike",:font_size => 16) # renders at 16pt
    def add_text(text, format_opts={})
      format_opts = options.text_format.merge(format_opts) if options.text_format
      pdf_writer.text(text, format_opts)
    end

    # Calls PDF::Writer#render and appends to <tt>output</tt>.
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
      info = ::PDF::Writer::Graphics::ImageInfo.new(File.open(path, "rb"))

      # reduce the size of the image until it fits into the requested box
      img_width, img_height =
        fit_image_in_box(info.width,width,info.height,height)
      
      # if the image is smaller than the box, calculate the white space buffer
      x, y = add_white_space(x,y,img_width,width,img_height,height)

      pdf_writer.add_image_from_file(path, x, y, img_width, img_height) 
    end

    # Draws some text on the canvas, surrounded by a box with rounded corners.
    #
    # Yields an OpenStruct which options can be defined on.
    # 
    # Example:
    #
    #    rounded_text_box(options.text) do |o|
    #      o.radius = 5
    #      o.width     = options.width  || 400
    #      o.height    = options.height || 130
    #      o.font_size = options.font_size || 12
    #      o.heading   = options.heading
    #   
    #      o.x = pdf_writer.absolute_x_middle - o.width/2
    #      o.y = 300
    #    end
    #
    def rounded_text_box(text)
      opts = OpenStruct.new
      yield(opts)
      
      resize_text_to_box(text, opts)
      
      pdf_writer.save_state
      draw_box(opts.x, opts.y, opts.width, opts.height, opts.radius, 
        opts.fill_color, opts.stroke_color)
      add_text_with_bottom_border(opts.heading, opts.x, opts.y,
        opts.width, opts.font_size) if opts.heading
      pdf_writer.restore_state

      start_position = opts.heading ? opts.y - 20 : opts.y
      draw_text(text, :y              => start_position,
                      :left           => opts.x,
                      :right          => opts.x + opts.width,
                      :justification  => opts.justification || :center,
                      :font_size      => opts.font_size)
      move_cursor_to(opts.y - opts.height)
    end

    # Adds n to pdf_writer.y, moving the vertical drawing position in the
    # document.
    def move_cursor(n) 
      pdf_writer.y += n
    end
    
    # Moves the cursor to a specific y coordinate in the document.
    def move_cursor_to(n)
      pdf_writer.y = n
    end

    # Moves the vertical drawing position in the document upwards by n.
    def move_up(n)
      pdf_writer.y += n
    end

    def move_down(n)
      pdf_writer.y -= n
    end
    
    # Adds a specified amount of whitespace above and below the code
    # in your block.  For example, if you want to surround the top and
    # bottom of a line of text with 5 pixels of whitespace:
    #
    #    pad(5) { add_text "This will be padded top and bottom" }
    def pad(y,&block)
      move_cursor(-y)
      block.call
      move_cursor(-y)
    end
    
    # Adds a specified amount of whitespace above the code in your block.  
    # For example, if you want to add a 10 pixel buffer to the top of a
    # line of text:
    #
    #    pad_top(10) { add_text "This will be padded on top" }
    def pad_top(y,&block)
      move_cursor(-y)
      block.call
    end
    
    # Adds a specified amount of whitespace below the code in your block.  
    # For example, if you want to add a 10 pixel buffer to the bottom of a
    # line of text:
    #
    #    pad_bottom(10) { add_text "This will be padded on bottom" }
    def pad_bottom(y,&block)
      block.call
      move_cursor(-y)
    end
    
    # Draws a PDF::SimpleTable using the given data (usually a Data::Table).
    # Takes all the options you can set on a PDF::SimpleTable object,
    # see the PDF::Writer API docs for details, or check our quick reference
    # at: 
    # 
    # http://stonecode.svnrepository.com/ruport/trac.cgi/wiki/PdfWriterQuickRef
    def draw_table(table_data, format_opts={})
      m = "PDF Formatter requires column_names to be defined"
      raise FormatterError, m if table_data.column_names.empty?
      
      table_data.rename_columns { |c| c.to_s } 
            
      if options.table_format
        format_opts =
          Marshal.load(Marshal.dump(options.table_format.merge(format_opts))) 
      end  
        
      old = pdf_writer.font_size
      
      ::PDF::SimpleTable.new do |table|          
        table.maximum_width = 500
        table.column_order  = table_data.column_names
        table.data = table_data
        table.data = [{}] if table.data.empty?                                                 
        apply_pdf_table_column_opts(table,table_data,format_opts)

        format_opts.each {|k,v| table.send("#{k}=", v) }  
        table.render_on(pdf_writer)
      end                                              
      
      pdf_writer.font_size = old
    end
        
    # This module provides tools to simplify some common drawing operations.
    # It is included by default in the PDF formatter.
    #
    module DrawingHelpers
      
      # Draws a horizontal line from x1 to x2
      def horizontal_line(x1,x2)
        pdf_writer.line(x1,cursor,x2,cursor)
        pdf_writer.stroke
      end 
      
      # Draws a horizontal line from left_boundary to right_boundary
      def horizontal_rule
        horizontal_line(left_boundary,right_boundary)                                            
      end                                            
      
      alias_method :hr, :horizontal_rule
                    
      # Draws a vertical line at x from y1 to y2
      def vertical_line_at(x,y1,y2)
        pdf_writer.line(x,y1,x,y2)
        pdf_writer.stroke 
      end
    
      # Alias for PDF::Writer#absolute_left_margin
      def left_boundary
        pdf_writer.absolute_left_margin
      end
      
      # Alias for PDF::Writer#absolute_right_margin
      def right_boundary
        pdf_writer.absolute_right_margin
      end
      
      # Alias for PDF::Writer#absolute_top_margin
      def top_boundary
        pdf_writer.absolute_top_margin
      end
      
      # Alias for PDF::Writer#absolute_bottom_margin
      def bottom_boundary
        pdf_writer.absolute_bottom_margin
      end
      
      # Alias for PDF::Writer#y
      def cursor
        pdf_writer.y
      end
      
      # Draws text at an absolute location, defined by
      # :y, :x1|:left, :x2|:right
      # 
      # All options to add_text are also supported.
      def draw_text(text,text_opts)
        ypos = cursor
        move_cursor_to(text_opts[:y]) if text_opts[:y]
        add_text(text,
          text_opts.merge(:absolute_left => text_opts[:x1] || text_opts[:left],
          :absolute_right => text_opts[:x2] || text_opts[:right]))
        move_cursor_to(ypos)
      end
      
      # Draws text at an absolute location, defined by
      # :y, :x1|:left
      #
      # The x position defaults to the left margin and the
      # y position defaults to the current cursor location.
      # 
      # Uses PDF::Writer#add_text, so it will ignore any options not supported
      # by that method.
      def draw_text!(text,text_opts)
        ypos = cursor
        pdf_writer.add_text(text_opts[:x1] || text_opts[:left] || left_boundary,
          text_opts[:y] || ypos,
          text,
          text_opts[:font_size],
          text_opts[:angle] || 0)
        move_cursor_to(ypos)
      end   
      
      def finalize
        render_pdf
      end
    end   

    include DrawingHelpers
    
    private
    
    def apply_pdf_table_column_opts(table,table_data,format_opts)
      column_opts = format_opts.delete(:column_options)

      if column_opts
        heading_opts = column_opts.delete(:heading)
        if column_opts[:justification]
          heading_opts ||= {}
          heading_opts = {
            :justification => column_opts[:justification]
          }.merge(heading_opts)
        end
        specific = get_specific_column_options(table_data.column_names,
                                               column_opts)
        columns = table_data.column_names.inject({}) { |s,c|
          s.merge( c => ::PDF::SimpleTable::Column.new(c) { |col|
            col.heading = create_heading(heading_opts) 
            column_opts.each { |k,v| col.send("#{k}=",v) }
            # use the specific column names now
            specific[c].each { |k,v| col.send("#{k}=",v) }
          })
        }
        table.columns = columns
      end
    end

    def get_specific_column_options(column_names,column_opts)
      column_names.inject({}) do |s,c|
        opts = column_opts.delete(c) || {}
        if opts[:heading]
          opts = opts.merge(:heading => create_heading(opts[:heading]))
        end
        s.merge(c => opts)
      end
    end
    
    def create_heading(heading_opts)
      heading_opts ||= {}
      ::PDF::SimpleTable::Column::Heading.new {|head|
        heading_opts.each {|k,v| head.send("#{k}=",v) }
      }
    end
    
    def grouping_columns
      data.data.to_a[0][1].column_names.dup.unshift(data.grouped_by)
    end
    
    def table_with_grouped_by_column
      Ruport::Data::Table.new(:column_names => grouping_columns)
    end
    
    def render_justified_or_separated_grouping
      table = table_with_grouped_by_column
      data.each do |name,group|
        group.each_with_index do |r,i|
          if i == 0
            table << { data.grouped_by => "<b>#{name}</b>" }.merge(r.to_hash)
          else
            table << r
          end
        end
        table << [" "] if options.style == :separated
      end
      render_table table, options.to_hash.merge(:formatter => pdf_writer)
    end
    
    def render_offset_grouping
      table = table_with_grouped_by_column
      data.each do |name,group|
        table << ["<b>#{name}</b>"]
        group.each {|r| table << r }
      end
      render_table table, options.to_hash.merge(:formatter => pdf_writer)
    end
    
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
    
    def resize_text_to_box(text,opts)
      loop do
        sz = pdf_writer.text_width(text, opts.font_size)
        opts.x + sz > opts.x + opts.width or break
        opts.font_size -= 1
      end
    end
    
    def draw_box(x,y,width,height,radius,fill_color=nil,stroke_color=nil)
      pdf_writer.fill_color(fill_color || Color::RGB::White)
      pdf_writer.stroke_color(stroke_color || Color::RGB::Black)
      pdf_writer.rounded_rectangle(x, y, width, height, radius).fill_stroke
    end
    
    def add_text_with_bottom_border(text,x,y,width,font_size)
      pdf_writer.line( x, y - 20, 
                       x + width, y - 20).stroke
      pdf_writer.fill_color(Color::RGB::Black)
      move_cursor_to(y - 3)
      add_text("<b>#{text}</b>",
        :absolute_left => x, :absolute_right => x + width,
        :justification => :center, :font_size => font_size)
    end
    
    def apply_page_format_template(t)
      t = (t || {}).merge(options.page_format || {})
      options.paper_size ||= t[:size]
      options.paper_orientation ||= t[:layout]
    end
    
    def apply_text_format_template(t)
      t = (t || {}).merge(options.text_format || {})
      options.text_format = t unless t.empty?
    end

    def apply_table_format_template(t)
      t = (t || {}).merge(options.table_format || {})
      options.table_format = t unless t.empty?
    end
    
    def apply_column_format_template(t)
      t = (t || {}).merge(options.column_format || {})
      column_opts = {}
      column_opts.merge!(:justification => t[:alignment]) if t[:alignment]
      column_opts.merge!(:width => t[:width]) if t[:width]
      unless column_opts.empty?
        if options.table_format
          if options.table_format[:column_options]
            options.table_format[:column_options] =
              column_opts.merge(options.table_format[:column_options])
          else
            options.table_format.merge!(:column_options => column_opts)
          end
        else
          options.table_format = { :column_options => column_opts }
        end
      end
    end
    
    def apply_heading_format_template(t)
      t = (t || {}).merge(options.heading_format || {})
      heading_opts = {}
      heading_opts.merge!(:justification => t[:alignment]) if t[:alignment]
      heading_opts.merge!(:bold => t[:bold]) unless t[:bold].nil?
      heading_opts.merge!(:title => t[:title]) if t[:title]
      unless heading_opts.empty?
        if options.table_format
          if options.table_format[:column_options]
            if options.table_format[:column_options][:heading]
              options.table_format[:column_options][:heading] =
                heading_opts.merge(
                  options.table_format[:column_options][:heading]
                )
            else
              options.table_format[:column_options].merge!(
                :heading => heading_opts
              )
            end
          else
            options.table_format.merge!(
              :column_options => { :heading => heading_opts }
            )
          end
        else
          options.table_format = {
            :column_options => { :heading => heading_opts }
          }
        end
      end
    end
    
    def apply_grouping_format_template(t)
      t = (t || {}).merge(options.grouping_format || {})
      options.style ||= t[:style]
    end
  end
end
