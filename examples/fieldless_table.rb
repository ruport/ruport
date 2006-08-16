require "ruport"
include Ruport


class Format::Plugin::FieldlessCSVPlugin < Format::Plugin::CSVPlugin
  rendering_options :show_field_names => false
  plugin_name :fieldless_csv
  register_on :table_engine
end

