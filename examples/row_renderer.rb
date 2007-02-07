require "ruport"

class RowRenderer < Ruport::Renderer

  include Ruport::Renderer::Helpers

  stage :row 
  required_option :record
  option :class_str

end

class HTML < Ruport::Format::HTML
  
  RowRenderer.add_format self, :html

  def build_row
    build_html_row(options.record,options.class_str)
  end

end

Ruport::Data::Table.load("hygjan2007.csv", :has_names => false) do |s,r|
  puts "<html><body><table>"
  RowRenderer.render_html(:record => r, :io => STDOUT)
  puts "</table></body></html>"
end
