require "ruport"

Ruport::Formatter::Template.create(:simple) do |format|
  format.page = {
    :size   => "LETTER",
    :layout => :landscape
  }
  format.text = {
    :font_size => 16
  }
  format.table = {
    :font_size      => 16,
    :show_headings  => false
  }
  format.column = {
    :alignment => :center,
  }                       
  format.heading = {
    :alignment => :right
  }
  format.grouping = {
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
