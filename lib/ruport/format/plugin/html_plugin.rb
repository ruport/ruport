module Ruport
  class Format::Plugin
    class HTMLPlugin < Format::Plugin
   
      rendering_options :red_cloth_enabled => true, :erb_enabled => true
      
      renderer :document 
      
      renderer :table do
        rc = data.inject(rendered_field_names) { |s,r| 
          row = r.map { |e| e.to_s.empty? ? "&nbsp;" : e }
          s + "|#{row.to_a.join('|')}|\n" 
        }
        Format.document :data => rc, :plugin => :html 
      end

      format_field_names do
        s = "|_." + data.column_names.join(" |_.") + "|\n"
      end

      plugin_name :html
      register_on :table_engine
      register_on :document_engine
      
    end        
  end
end
