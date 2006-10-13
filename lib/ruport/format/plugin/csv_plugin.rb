module Ruport
  class Format::Plugin
    class CSVPlugin < Format::Plugin
      
      helper(:init_plugin) { |eng| require "fastercsv" }

      format_field_names do
        if data.column_names.empty?
          ""
        else
          FasterCSV.generate { |csv| csv << data.column_names }
        end
      end
      
      renderer :table do
        rendered_field_names +
        FasterCSV.generate { |csv| data.each { |r| csv << r } }
      end
      
      plugin_name :csv
      register_on :table_engine
    end
  end
end


