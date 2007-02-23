require "ruport"

puts "<html><body><table>"

Ruport::Data::Table.load("example.csv", :has_names => false) do |s,r|
  Ruport::Data::Record.new(r).as(:html, :record => r, :io => STDOUT)
end

puts "</table></body></html>"
