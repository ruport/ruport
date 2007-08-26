require "ruport"

Ruport::Formatter::Template.create(:simple) do |t|
  t.page_format = {
    :size   => "LETTER",
    :layout => :landscape
  }
  t.text_format = {
    :font_size => 16
  }
  t.table_format = {
    :font_size      => 16,
    :show_headings  => false
  }
  t.column_format = {
    :alignment => :center,
    :heading => { :justification => :right }
  }
  t.grouping_format = {
    :style => :separated
  }
end

Ruport::Formatter::Template.create(:derived, :base => :simple) do |t|
  t.table_format[:font_size] = 12
end

# Uncomment this section to use the :simple2 template
#
# Ruport::Formatter::Template.create(:simple2) do |t|
#   t.page_layout = :portrait
#   t.grouping_style = :offset
# end  
# 
# class Ruport::Formatter::PDF
#   
#   def apply_template
#     options.paper_orientation = template.page_layout
#     options.style = template.grouping_style
#   end
#   
# end 

t = Table(%w[a b c]) << [1,2,3] << [1,"hello",6] << [2,3,4] 
g = Grouping(t, :by => "a")

puts g.to_pdf(:template => :simple)
#puts g.to_pdf(:template => :derived)
#puts g.to_pdf(:template => :simple2)
#puts g.to_pdf