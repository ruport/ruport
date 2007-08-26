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
  # This class provides text output for Ruport's Row,Table,Group, and Grouping
  # renderers
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
  # but can be overridden       
  #
  # <tt>:alignment:</tt> Defaults to left justify text and right justify numbers.
  # centers all fields when set to :center
  #
  # <tt>:table_width:</tt> Will truncate rows at this limit. 
  #
  # <tt>:show_table_headers:</tt> Defaults to true
  #
  # <tt>:show_group_headers:</tt> Defaults to true  
  #
  # <tt>:ignore_table_width:</tt> When set to true, outputs full table without
  # truncating it.  Useful for file output
  class Formatter::Text < Formatter
   
    renders :text, :for => [ Renderer::Row, Renderer::Table,
                             Renderer::Group, Renderer::Grouping ]

    opt_reader :max_col_width, :alignment, :table_width, 
               :show_table_headers, :show_group_headers,
               :ignore_table_width
    
    # Hook for setting available options using a template.
    def apply_template
      if t = template.table_format
        options.show_table_headers = t[:show_headings] unless
          t[:show_headings].nil?
        options.table_width = t[:width] if t[:width]
        options.ignore_table_width = t[:ignore_width] unless
          t[:ignore_width].nil?
      end

      if t = template.column_format
        options.max_col_width = t[:maximum_width] if t[:maximum_width]
        options.alignment = t[:alignment] if t[:alignment]
      end

      if t = template.grouping_format
        options.show_group_headers = t[:show_headings] unless
          t[:show_headings].nil?
      end
    end

    # Checks to ensure the table is not empty and then calls
    # calculate_max_col_widths
    #
    def prepare_table
      raise Ruport::FormatterError, "Can't output table without " +
        "data or column names." if data.empty? && data.column_names.empty?
      calculate_max_col_widths
    end

    # Uses the column names from the given Data::Table to generate a table
    # header.
    #
    # Calls fit_to_width to truncate table heading if necessary.
    #
    def build_table_header
      return unless should_render_column_names?

      c = data.column_names.enum_for(:each_with_index).map { |f,i|
        f.to_s.center(max_col_width[i])
      }

      output << fit_to_width("#{hr}| #{c.join(' | ')} |\n")
    end

    # Generates the body of the text table. 
    #
    # Defaults to numeric values being right justified, and other values being
    # left justified.  Can be changed to support centering of output by
    # setting options.alignment to :center
    #
    # Uses fit_to_width to truncate table if necessary.
    #
    def build_table_body
      output << fit_to_width(hr)
      return if data.empty?

      calculate_max_col_widths unless max_col_width

      render_data_by_row do |rend|
        rend.options do |o|
          o.max_col_width = max_col_width
          o.alignment     = alignment
          o.table_width   = table_width   
          o.ignore_table_width = ignore_table_width
        end
      end

      output << fit_to_width(hr)
    end
    
    # Generates a formatted text row. 
    #
    # Defaults to numeric values being right justified, and other values being
    # left justified.  Can be changed to support centering of output by
    # setting options.alignment to :center
    #
    # Uses fit_to_width to truncate table if necessary.
    #
    def build_row
      max_col_widths_for_row(data) unless max_col_width

      data.enum_for(:each_with_index).inject(line=[]) { |s,e|
        field,index = e
        if alignment.eql? :center
          line << field.to_s.center(max_col_width[index])
        else
          align = field.is_a?(Numeric) ? :rjust : :ljust
          line << field.to_s.send(align, max_col_width[index])
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
    # Table renderer.
    #
    def build_group_body
      render_table data, options
    end

    # Generates the body for a grouping. Iterates through the groups and
    # renders them using the group renderer.
    #
    def build_grouping_body
      render_inline_grouping(options)
    end
    
    # Returns false if column_names are empty or options.show_table_headers
    # is false/nil.  Returns true otherwise.
    #
    def should_render_column_names?
      not data.column_names.empty? || !show_table_headers
    end

    # Generates the horizontal rule by calculating the total table width and
    # then generating a bar that looks like this:
    #
    #   "+------------------+"
    def hr
      ref = data.column_names.empty? ? data[0].to_a : data.column_names
      len = max_col_width.inject(ref.length * 3) {|s,e|s+e}
      "+" + "-"*(len-1) + "+\n"
    end
    
    # Returns options.table_width if specified.
    #
    # Otherwise, uses SystemExtensions to determine terminal width.
    def width
      table_width || SystemExtensions.terminal_width
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

    # determines the text widths for each column.
    def calculate_max_col_widths
      # allow override
      return if max_col_width

      options.max_col_width = []

      unless data.column_names.empty?
        data.column_names.each_index do |i| 
          max_col_width[i] = data.column_names[i].to_s.length
        end
      end
          
      data.each { |r| max_col_widths_for_row(r) } 
    end
    
    # used to calculate the <tt>max_col_widths</tt> array.
    # Override this to tweak the automatic column size adjustments.
    def max_col_widths_for_row(row)
      options.max_col_width ||= []
      row.each_with_index do |f,i|
        if !max_col_width[i] || f.to_s.length > max_col_width[i]
          max_col_width[i] = f.to_s.length
        end
      end
    end

  end
end
