module Ruport
  class Format::Plugin
    class CSVPlugin < Format::Plugin
      
      helper(:init_plugin) { |eng| require "fastercsv" }

      format_field_names do
        FasterCSV.generate { |csv| csv << data.column_names }
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


