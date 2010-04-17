module Ruport
  class Formatter::PrawnPDF < Formatter

    renders :prawn_pdf, :for =>[Controller::Row, Controller::Table,
                              Controller::Group, Controller::Grouping]

    attr_accessor :pdf

    def initialize
      require 'prawn'
      require 'prawn/layout'
    end

    def pdf
      @pdf ||= ::Prawn::Document.new()
    end

    def draw_table(table)
      pdf.table(table_to_array(table))
    end

    def table_to_array(tbl)
      tbl.map { |row| row.to_a}
    end

    def finalize
      output << pdf.render
    end
  end
end
