# Ruport : Extensible Reporting System                                
#
# formatter/text.rb provides text formatting for Ruport.
#     
# Created by Gregory Brown, some time around Spring 2006.
# Copyright (C) 2006-2007, All Rights Reserved.  
#
# Mathijs Mohlmann and Marshall T. Vandegrift have provided some patches for
# this class, see AUTHORS file for details.
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.
module Ruport
  
  # This class provides text output for Ruport's Row, Table, Group, and
  # Grouping controllers
  #
  # It handles things like automatically truncating tables that go off the
  # edge of the screen in the console, proper column alignment, and pretty
  # output that looks something like this:
  #
  #   +------------------------------+
  #   | apple | banana | strawberry  |
  #   +------------------------------+
  #   | yes   | no     | yes         |
  #   | yes   | yes    | red snapper |
  #   | what  | the    | red snapper |
  #   +------------------------------+ 
  #
  # === Supported Options 
  #
  # <tt>:max_col_width:</tt> Ordinal array of column widths.  Set automatically
  # but can be overridden.
  #
  # <tt>:alignment:</tt> Defaults to left justify text and right justify
  # numbers. Centers all fields when set to :center.
  #
  # <tt>:table_width:</tt> Will truncate rows at this limit.
  #
  # <tt>:show_table_headers:</tt> Defaults to true
  #
  # <tt>:show_group_headers:</tt> Defaults to true  
  #
  # <tt>:ignore_table_width:</tt> When set to true, outputs full table without
  # truncating it.  Useful for file output.
  class Formatter::Text < Formatter
   
    renders [:txt, :text], :for => [ Controller::Row, Controller::Table,
                                     Controller::Group, Controller::Grouping ]

    # Hook for setting available options using a template. See the template 
    # documentation for the available options and their format.
    def apply_template
      apply_table_format_template(template.table)
      apply_column_format_template(template.column)
      apply_grouping_format_template(template.grouping)
    end

    # Checks to ensure the table is not empty and then calls
    # calculate_max_col_widths.
    #
    def prepare_table
      raise Ruport::FormatterError, "Can't output table without " +
        "data or column names." if data.empty? && data.column_names.empty?
      calculate_max_col_widths
    end

    # Uses the column names from the given Data::Table to generate a table
    # header.
    #
    # Calls fit_to_width to truncate the table heading if necessary.
    #
    def build_table_header
      return unless should_render_column_names?

      c = data.column_names.enum_for(:each_with_index).map { |f,i|
        f.to_s.center(options.max_col_width[i])
      }

      output << fit_to_width("#{hr}| #{c.join(' | ')} |\n")
    end

    # Generates the body of the text table. 
    #
    # Defaults to numeric values being right justified, and other values being
    # left justified.  Can be changed to support centering of output by
    # setting options.alignment to :center
    #
    # Uses fit_to_width to truncate the table if necessary.
    #
    def build_table_body
      output << fit_to_width(hr)
      return if data.empty?

      calculate_max_col_widths unless options.max_col_width

      data.each { |row| build_row(row) }

      output << fit_to_width(hr)
    end
    
    # Generates a formatted text row. 
    #
    # Defaults to numeric values being right justified, and other values being
    # left justified.  Can be changed to support centering of output by
    # setting options.alignment to :center
    #
    # Uses fit_to_width to truncate the row if necessary.
    #
    def build_row(data = self.data)
      max_col_widths_for_row(data) unless options.max_col_width

      data.enum_for(:each_with_index).inject(line=[]) { |s,e|
        field,index = e
        if options.alignment.eql? :center
          line << field.to_s.center(options.max_col_width[index])
        else
          align = field.is_a?(Numeric) ? :rjust : :ljust
          line << field.to_s.send(align, options.max_col_width[index])
        end
      }
      output << fit_to_width("| #{line.join(' | ')} |\n")
    end

    # Renders the header for a group using the group name.
    #
    def build_group_header
      output << "#{data.name}:\n\n"
    end
    
    # Creates the group body. Since group data is a table, just uses the
    # Table controller.
    #
    def build_group_body
      render_table data, options
    end

    # Generates the body for a grouping. Iterates through the groups and
    # renders them using the group controller.
    #
    def build_grouping_body
      render_inline_grouping(options)
    end
    
    # Returns false if column_names are empty or options.show_table_headers
    # is false/nil.  Returns true otherwise.
    #
    def should_render_column_names?
      not data.column_names.empty? || !options.show_table_headers
    end

    # Generates the horizontal rule by calculating the total table width and
    # then generating a bar that looks like this:
    #
    #   "+------------------+"
    def hr
      ref = data.column_names.empty? ? data[0].to_a : data.column_names
      len = options.max_col_width.inject(ref.length * 3) {|s,e|s+e}
      "+" + "-"*(len-1) + "+\n"
    end
    
    # Returns options.table_width if specified.
    #
    # Otherwise, uses SystemExtensions to determine terminal width.
    def width
      options.table_width ||= SystemExtensions.terminal_width
    end

    # Truncates a string so that it does not exceed Text#width
    def fit_to_width(s)      
      return s if options.ignore_table_width
      # workaround for Rails setting terminal_width to 1
      max_width = width < 2 ? 80 : width
      
      s.split("\n").each { |r|
         r.gsub!(/\A.{#{max_width+1},}/) { |m| m[0,max_width-2] + ">>" }
      }.join("\n") + "\n"
    end

    # Determines the text widths for each column.
    def calculate_max_col_widths
      # allow override
      return if options.max_col_width

      options.max_col_width = []

      unless data.column_names.empty?
        data.column_names.each_index do |i| 
          options.max_col_width[i] = data.column_names[i].to_s.length
        end
      end
          
      data.each { |r| max_col_widths_for_row(r) } 
    end
    
    # Used to calculate the <tt>max_col_widths</tt> array.
    # Override this to tweak the automatic column size adjustments.
    def max_col_widths_for_row(row)
      options.max_col_width ||= []
      row.each_with_index do |f,i|
        if !options.max_col_width[i] || f.to_s.length > options.max_col_width[i]
          options.max_col_width[i] = f.to_s.length
        end
      end
    end
    
    private
    
    def apply_table_format_template(t)
      t = (t || {}).merge(options.table_format || {})
      options.show_table_headers = t[:show_headings] if
        options.show_table_headers.nil?
      options.table_width ||= t[:width]
      options.ignore_table_width = t[:ignore_width] if
        options.ignore_table_width.nil?
    end
    
    def apply_column_format_template(t)
      t = (t || {}).merge(options.column_format || {})
      options.max_col_width ||= t[:maximum_width]
      options.alignment ||= t[:alignment]
    end
    
    def apply_grouping_format_template(t)
      t = (t || {}).merge(options.grouping_format || {})
      options.show_group_headers = t[:show_headings] if
        options.show_group_headers.nil?
    end

  end
end
