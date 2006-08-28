require "ruport"
include Ruport

# this shows how you can create your own plugin with some default rendering
# options as a shortcut.

class Format::Plugin::FieldlessCSVPlugin < Format::Plugin::CSVPlugin
  rendering_options :show_field_names => false
  plugin_name :fieldless_csv
  register_on :table_engine
end

puts [[1,2,3]].to_table(%w[a b c]).to_fieldless_csv
