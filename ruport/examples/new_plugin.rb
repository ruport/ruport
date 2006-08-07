require "rubygems"
require "ruport"

include Ruport

class Format::Plugin::Text < Ruport::Format::Plugin
  renderer :table do
    data.inject(rendered_field_names) { |s,r| 
      s << r.to_a.join("()") << "\n" 
    }
  end

  format_field_names do
    data.column_names.join("---") << "\n"
  end

  register_on :table_engine
end

puts Format.table({ :data => [[1,2],[3,4]].to_table(:column_names =>%w[a b]),
                    :plugin => :text })
