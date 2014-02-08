module Ruport
  class Formatter::PrawnPDF < Formatter

    renders :prawn_pdf, :for =>[Controller::Row, Controller::Table,
                              Controller::Group, Controller::Grouping]

    attr_accessor :pdf

    def method_missing(id,*args, &block)
      pdf.send(id,*args, &block)
    end

    def initialize
      require 'prawn'
      require 'prawn/layout'
    end

    def pdf
      @pdf ||= (options.formatter || 
        ::Prawn::Document.new(options[:pdf_format] || {} ))
    end

    def draw_table(table, format_opts={}, &block)
      m = "PDF Formatter requires column_names to be defined"
      raise FormatterError, m if table.column_names.empty?

      table.rename_columns { |c| c.to_s }

      table_array = [table.column_names]
      table_array += table_to_array(table)
      table_array.map { |array| array.map! { |elem| elem.class != String ? elem.to_s : elem }}

      if options[:table_format]
        opt = options[:table_format] 
      else
        opt = format_opts
      end

      pdf.table(table_array, opt, &block)

    end

    def table_to_array(tbl)
      tbl.map { |row| row.to_a}
    end

    def finalize
      output << pdf.render
    end

    def build_table_body(&block)
      draw_table(data, &block)
    end

    def build_group_body
      render_table data, options.to_hash.merge(:formatter => pdf)
    end

    def build_grouping_body(&block)
      data.each do |name,group|

        # Group heading
        move_down(20)
        text name, :style => :bold, :size => 15

        # Table
        move_down(10)
        draw_table group, &block
      end
    end
  end
end
