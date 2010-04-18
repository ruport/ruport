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
      @pdf ||= (options.formatter || ::Prawn::Document.new())
    end

    def draw_table(table)

      table_array = [table.column_names]
      table_array += table_to_array(table)
      pdf.table(table_array) do
        style row(0), :font_style => :bold
      end
    end

    def table_to_array(tbl)
      tbl.map { |row| row.to_a}
    end

    def finalize
      output << pdf.render
    end

    def build_table_body
      draw_table(data)
    end

    def build_group_body
      render_table data, options.to_hash.merge(:formatter => pdf)
    end

    def build_grouping_body
      data.each do |name,group|

        # Group heading
        move_down(20)
        text name, :style => :bold, :size => 15

        # Table
        move_down(10)
        draw_table group
      end
    end
  end
end
