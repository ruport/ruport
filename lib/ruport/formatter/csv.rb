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
  # and Grouping controllers.  It is a light wrapper around
  # James Edward Gray II's FasterCSV.
  #
  # === Rendering Options
  #                                                     
  # <tt>:style</tt> Used for grouping (:inline,:justified,:raw)      
  #
  # <tt>:format_options</tt> A hash of FasterCSV options  
  #
  # <tt>:formatter</tt> An existing FasterCSV object to write to
  #
  # <tt>:show_table_headers</tt> True by default
  #
  # <tt>:show_group_headers</tt> True by default
  #
  class Formatter::CSV < Formatter
    
    renders :csv, :for => [ Controller::Row,   Controller::Table, 
                            Controller::Group, Controller::Grouping ]
    
    def initialize
      require "fastercsv" unless RUBY_VERSION > "1.9"   
    end

    attr_writer :csv_writer

    # Hook for setting available options using a template. See the template 
    # documentation for the available options and their format.
    def apply_template
      apply_table_format_template(template.table)
      apply_grouping_format_template(template.grouping)

      options.format_options ||= template.format_options
    end

    # Returns the current FCSV object or creates a new one if it has not
    # been set yet. Note that FCSV(sig) has a cache and returns the *same*
    # FCSV object if writing to the same underlying output with the same
    # options.
    #
    def csv_writer
      @csv_writer ||= options.formatter ||
        FCSV(output, options.format_options || {})
    end

    # Generates table header by turning column_names into a CSV row.
    # Uses the row controller to generate the actual formatted output
    #
    # This method does not do anything if options.show_table_headers is false
    # or the Data::Table has no column names.
    def build_table_header
      unless data.column_names.empty? || !options.show_table_headers
        render_row data.column_names, :format_options => options.format_options,
                                      :formatter => csv_writer
      end
    end

    # Calls the row controller for each row in the Data::Table
    def build_table_body
      fcsv = csv_writer
      data.each { |row| fcsv << row }
    end

    # Produces CSV output for a data row.
    def build_row(data = self.data)
      csv_writer << data
    end
    
    # Renders the header for a group using the group name.
    # 
    def build_group_header
      csv_writer << [data.name.to_s] << []
    end
    
    # Renders the group body - uses the table controller to generate the output.
    #
    def build_group_body
      render_table data, options.to_hash
    end
    
    # Generates a header for the grouping using the grouped_by column and the
    # column names.
    #
    def build_grouping_header
      unless options.style == :inline
        csv_writer << [data.grouped_by] + grouping_columns
      end
    end
   
    # Determines the proper style to use and renders the Grouping.
    def build_grouping_body
      case options.style
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
      data.data.to_a[0][1].column_names
    end
    
    def render_justified_or_raw_grouping
      data.each do |_,group|
        prefix = [group.name.to_s]
        group.each do |row|
          csv_writer << prefix + row.to_a
          prefix = [nil] if options.style == :justified
        end
        csv_writer << []
      end
    end
    
    def apply_table_format_template(t)
      t = (t || {}).merge(options.table_format || {})
      options.show_table_headers = t[:show_headings] if
        options.show_table_headers.nil?
    end
    
    def apply_grouping_format_template(t)
      t = (t || {}).merge(options.grouping_format || {})
      options.style ||= t[:style]
      options.show_group_headers = t[:show_headings] if
        options.show_group_headers.nil?
    end
    
  end
end
