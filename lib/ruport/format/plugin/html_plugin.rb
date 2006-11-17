module Ruport
  class Format::Plugin
    class HTMLPlugin < Format::Plugin
   
      rendering_options :red_cloth_enabled => true, :erb_enabled => true

      renderer :document 
      
      renderer :table do
        data.inject("\t<table>\n" + rendered_field_names) do |s,r| 
          row = r.map { |e| e.to_s.empty? ? "&nbsp;" : e }
          classstr = defined?(r.tags) ? 
            r.tags.inject("") {|cs,c| cs + " class='#{c}'" } : ""
          s + "\t\t<tr#{classstr}>\n\t\t\t<td#{classstr}>" +
            row.to_a.join("</td>\n\t\t\t<td#{classstr}>") + 
            "</td>\n\t\t</tr>\n"
        end 
      end

      format_field_names do
        "\t\t<tr>\n\t\t\t<th>" + 
          data.column_names.join("</th>\n\t\t\t<th>") + 
          "</th>\n\t\t</tr>\n"
      end

      plugin_name :html
      register_on :table_engine
      register_on :document_engine
      
    end        
  end
end
