module Ruport::Format

  # This plugin implements the CSV format for tabular data output. 
  # See also:  Renderer::Table
  class CSV < Plugin
    
    # Generates table header by turning column_names into a CSV row.
    # Uses build_csv_row to generate the actual formatted output
    #
    # This method does not do anything if options.show_table_headers is false or
    # the Data::Table has no column names.
    def build_table_header
      unless data.column_names.empty? || !options.show_table_headers
        build_csv_row(data.column_names)
      end
    end

    # Calls build_csv_row for each row in the Data::Table
    def build_table_body
      data.each { |r| build_csv_row(r) }
    end

    # Produces CSV output for a data row.
    def build_csv_row(row)
      require "fastercsv"
      FCSV(output) { |csv| csv << row }
    end
  end
end
