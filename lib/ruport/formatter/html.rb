# Ruport : Extensible Reporting System                                
#
# formatter/html.rb provides html formatting for Ruport.
#     
# Created by Gregory Brown, late 2005.  Updated numerous times as needed to 
# fit new formatting systems.
#    
# Copyright (C) 2005-2007 Gregory Brown, All Rights Reserved.  
#
# This is free software distributed under the same terms as Ruby 1.8
# See LICENSE and COPYING for details.   
#
module Ruport
  # This class produces HTML output for Ruport's Row, Table, Group, and
  # Grouping controllers.  It can be subclassed, as it has some helper methods
  # that might be useful for custom output.
  #
  # === Rendering Options
  #
  # <tt>:show_table_headers</tt>  True by default   
  #
  # <tt>:show_group_headers</tt>  True by default   
  #
  # <tt>:style</tt> Used for grouping (:inline, :justified)
  #
  class Formatter::HTML < Formatter    
    
    renders :html, :for => [ Controller::Row, Controller::Table,
                             Controller::Group, Controller::Grouping ]

    # Hook for setting available options using a template. See the template 
    # documentation for the available options and their format.
    def apply_template
      apply_table_format_template(template.table)
      apply_grouping_format_template(template.grouping)
    end

    # Generates table headers based on the column names of your Data::Table.  
    #
    # This method does not do anything if options.show_table_headers is false
    # or the Data::Table has no column names.
    def build_table_header
      output << "\t<table>\n"
      unless data.column_names.empty? || !options.show_table_headers
        output << "\t\t<tr>\n\t\t\t<th>" + 
          data.column_names.join("</th>\n\t\t\t<th>") + 
          "</th>\n\t\t</tr>\n"
      end
    end
    
    # Uses the Row controller to build up the table body.
    # Replaces nil and empty strings with "&nbsp;" 
    def build_table_body
      data.each do |row|
        build_row(row.map { |e| e.to_s.empty? ? "&nbsp;" : e })
      end
    end

    # Simply closes the table tag. 
    def build_table_footer
      output << "\t</table>\n"
    end
  
    # Renders individual rows for the table.
    def build_row(data = self.data)
      output <<
        "\t\t<tr>\n\t\t\t<td>" +
        data.to_a.join("</td>\n\t\t\t<td>") +
        "</td>\n\t\t</tr>\n"
    end

    # Renders the header for a group using the group name.
    #
    def build_group_header
      output << "\t<p>#{data.name}</p>\n"
    end

    # Creates the group body. Since group data is a table, just uses the
    # Table controller.
    #
    def build_group_body
      render_table data, options.to_hash
    end

    # Generates the body for a grouping. Iterates through the groups and
    # renders them using the group controller.
    #
    def build_grouping_body
      case options.style
      when :inline
        render_inline_grouping(options)
      when :justified
        render_justified_grouping
      end
    end

    # Generates <table> tags enclosing the yielded content.
    #
    # Example:  
    #
    #   output << html_table { "<tr><td>1</td><td>2</td></tr>\n" }
    #   #=> "<table>\n<tr><td>1</td><td>2</td></tr>\n</table>\n"
    #
    def html_table
      "<table>\n" << yield << "</table>\n"
    end

    # Uses RedCloth to turn a string containing textile markup into HTML.
    #
    # Example:
    #
    #   textile "*bar*" #=> "<p><strong>foo</strong></p>"
    #
    def textile(s)   
      require "redcloth"
      RedCloth.new(s).to_html   
    rescue LoadError
      raise RuntimeError, "You need RedCloth!\n gem install RedCloth -v 3.0.3"
    end
    
    private
    
    def render_justified_grouping
      output << "\t<table>\n\t\t<tr>\n\t\t\t<th>" +
        "#{data.grouped_by}</th>\n\t\t\t<th>" +
        grouping_columns.join("</th>\n\t\t\t<th>") + 
        "</th>\n\t\t</tr>\n"
      data.each do |name, group|                     
        group.each_with_index do |row, i|
          output << "\t\t<tr>\n\t\t\t"
          if i == 0
            output << "<td class=\"groupName\">#{name}</td>\n\t\t\t<td>"
          else
            output << "<td>&nbsp;</td>\n\t\t\t<td>"
          end
          output << row.to_a.join("</td>\n\t\t\t<td>") +
            "</td>\n\t\t</tr>\n"
        end
      end
      output << "\t</table>\n"
    end
    
    def grouping_columns
      data.data.to_a[0][1].column_names
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
