module Ruport
  # Produces HTML output for tabular data.
  #
  # See also Renderer::Table
  class Formatter::HTML < Formatter    
    
    renders :html, :for => [ Renderer::Row, Renderer::Table,
                             Renderer::Group, Renderer::Grouping ]

    opt_reader :show_table_headers, :class_str, :show_group_headers
    
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
    
    # Generates the <tr> and <td> tags for each row, calling to_s on each
    # element of the Record.  If the Record has been tagged, the tags will be
    # converted into class attributes in the HTML output.
    #
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

    def build_grouping_body
      data.each do |_,group|
        render_group group, options.to_hash
        output << "\n"
      end
    end

    # Renders individual rows for the table
    def build_row
      output <<
        "\t\t<tr#{class_str}>\n\t\t\t<td#{class_str}>" +
        data.to_a.join("</td>\n\t\t\t<td#{class_str}>") +
        "</td>\n\t\t</tr>\n"
    end

  end
end
