require "ruport"
require "rubygems"   

class MyReport < Ruport::Report
  renders_as_grouping
  
  def generate
    table = Table(%w[a b c]) << [1,2,3] << [4,5,6] << [1,7,9]
    Grouping(table,:by => "a")
  end
end

a = MyReport.new(:pdf) 
[:justified, :separated, :inline, :offset].each do |style|
  a.run(:style => style) { |r| r.write("#{style}.pdf") } 
end