module Ruport::Format
  # Produces HTML output for tabular data.
  #
  # See also Renderer::Table
  class HTML < Plugin
    
    # Generates table headers based on the column names of your Data::Table.  
    #
    # This method does not do anything if layout.show_table_headers is false or
    # the Data::Table has no column names.
    def build_table_header
      output << "\t<table>\n"
      unless data.column_names.empty? || !layout.show_table_headers
        output << "\t\t<tr>\n\t\t\t<th>" + 
          data.column_names.join("</th>\n\t\t\t<th>") + 
          "</th>\n\t\t</tr>\n"
      end
    end
    
    def build_table_body
      output << data.inject("") do |s,r| 
        row = r.map { |e| e.to_s.empty? ? "&nbsp;" : e }
        classstr = r.tags.inject("") {|cs,c| cs + " class='#{c}'" } 
        s + "\t\t<tr#{classstr}>\n\t\t\t<td#{classstr}>" +
          row.to_a.join("</td>\n\t\t\t<td#{classstr}>") + 
          "</td>\n\t\t</tr>\n"
      end 
    end

    def build_table_footer
      output << "\t</table>"
    end

  end
end
