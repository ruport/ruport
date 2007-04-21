module Ruport
  # Produces HTML output for tabular data.
  #
  class Formatter::HTML < Formatter    
    
    renders :html, :for => [ Renderer::Row, Renderer::Table,
                             Renderer::Group, Renderer::Grouping ]

    opt_reader :show_table_headers, :show_group_headers
    
    # Generates table headers based on the column names of your Data::Table.  
    #
    # This method does not do anything if options.show_table_headers is false or
    # the Data::Table has no column names.
    def build_table_header
      output << "\t<table>\n"
      unless data.column_names.empty? || !show_table_headers
        output << "\t\t<tr>\n\t\t\t<th>" + 
          data.column_names.join("</th>\n\t\t\t<th>") + 
          "</th>\n\t\t</tr>\n"
      end
    end
    
    def build_table_body
      render_data_by_row do |rend|
        r = rend.data
        rend.data = r.map { |e| e.to_s.empty? ? "&nbsp;" : e }
      end
    end

    # Simply closes the table tag. 
    def build_table_footer
      output << "\t</table>"
    end
  
    # Renders individual rows for the table
    def build_row
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
    # Table renderer.
    #
    def build_group_body
      render_table data, options.to_hash
    end

    # Generates the body for a grouping. Iterates through the groups and
    # renders them using the group renderer.
    #
    def build_grouping_body
      render_inline_grouping(options)
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

  end
end
