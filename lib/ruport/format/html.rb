module Ruport::Format
  # Produces HTML output for tabular data.
  #
  # See also Renderer::Table
  class HTML < Plugin
    
    # Generates table headers based on the column names of your Data::Table.  
    #
    # This method does not do anything if options.show_table_headers is false or
    # the Data::Table has no column names.
    def build_table_header
      output << "\t<table>\n"
      unless data.column_names.empty? || !options.show_table_headers
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
      data.each do |r| 
        row = r.map { |e| e.to_s.empty? ? "&nbsp;" : e }
        classstr = 
          r.tags.length > 0 ? " class='#{r.tags.to_a.join(' ')}'" : ""
        Ruport::Renderer::Row.render_html( 
         :class_str => classstr, :io => output) { |rend| rend.data = r  }
      end
    end

    # Simply closes the table tag. 
    def build_table_footer
      output << "\t</table>"
    end

    # Renders individual rows for the table
    def build_row
      output <<
        "\t\t<tr#{options.class_str}>\n\t\t\t<td#{options.class_str}>" +
        data.to_a.join("</td>\n\t\t\t<td#{options.class_str}>") +
        "</td>\n\t\t</tr>\n"
    end

  end
end
