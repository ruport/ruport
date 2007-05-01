# Ruport : Extensible Reporting System                                
#
# formatter/csv.rb provides csv formatting for Ruport.
#     
# Original code dates back to the earliest versions of Ruport in August 2005
# Extended over time, with much of the existing code being added around
# December 2006.
#    
# Copyright (C) 2005-2007 Gregory Brown, All Rights Reserved.  
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.   
#
module Ruport

  # This formatter implements the CSV format for Ruport's Row, Table, Group
  # and Grouping renderers.  It is a light wrapper around James Edward Gray II's
  # FasterCSV.
  #
  # === Rendering Options
  #                                                     
  # <tt>:style</tt> Used for grouping (:inline,:justified,:raw)      
  #
  # <tt>:format_options</tt> A hash of FasterCSV options  
  #
  # <tt>:show_table_headers</tt> True by default
  #
  # <tt>:show_group_headers</tt> True by default
  #
  class Formatter::CSV < Formatter
    
    renders :csv, :for => [ Renderer::Row,   Renderer::Table, 
                            Renderer::Group, Renderer::Grouping ]

    opt_reader :show_table_headers, 
               :format_options, 
               :show_group_headers,
               :style

    # Generates table header by turning column_names into a CSV row.
    # Uses the row renderer to generate the actual formatted output
    #
    # This method does not do anything if options.show_table_headers is false
    # or the Data::Table has no column names.
    def build_table_header
      unless data.column_names.empty? || !show_table_headers
        render_row data.column_names, :format_options => format_options 
      end
    end

    # Calls the row renderer for each row in the Data::Table
    def build_table_body
      render_data_by_row { |r| 
        r.options.format_options = format_options
      }
    end

    # Produces CSV output for a data row.
    def build_row
      require "fastercsv"
      output << FCSV.generate_line(data,format_options || {})
    end
    
    # Renders the header for a group using the group name.
    # 
    def build_group_header
      output << data.name.to_s << "\n\n"
    end
    
    # Renders the group body - uses the table renderer to generate the output.
    #
    def build_group_body
      render_table data, options.to_hash
    end
    
    # Generates a header for the grouping using the grouped_by column and the
    # column names.
    #
    def build_grouping_header
      unless style == :inline
        output << "#{data.grouped_by}," << grouping_columns
      end
    end
   
    # determines the proper style to use and renders the Grouping.
    def build_grouping_body
      case style
      when :inline
        render_inline_grouping(options)
      when :justified, :raw
        render_justified_or_raw_grouping
      else
        raise NotImplementedError, "Unknown style"
      end
    end
    
    private
    
    def grouping_columns
      require "fastercsv"
      data.data.to_a[0][1].column_names.to_csv
    end
    
    def render_justified_or_raw_grouping
      data.each do |_,group|
        output << "#{group.name}" if style == :justified
        group.each do |row|
          output << "#{group.name if style == :raw}," << row.to_csv
        end
        output << "\n"
      end
    end
  end
end
