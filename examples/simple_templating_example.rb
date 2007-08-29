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
  }                       
  t.heading_format = {
    :alignment => :right
  }
  t.grouping_format = {
    :style => :separated
  }
end

Ruport::Formatter::Template.create(:derived, :base => :simple) do |t|
  t.table_format[:show_headings] = true
end

t = Table(%w[a b c]) << [1,2,3] << [1,"hello",6] << [2,3,4] 
g = Grouping(t, :by => "a")

puts g.to_pdf(:template => :simple)
#puts g.to_pdf(:template => :derived)
