require "ruport"
a = [ ['a',7],['b',5],['c',11],
      ['d',9],['a',3],['b',2] ].to_table(%w[letter num])
puts "Initial Data:\n#{a}"
b = a.split(:group => "letter")
totals = [].to_table(%w[group sum])
b.each_group { |x| totals << [x,b[x].sum("num")] }
puts "After grouping:\n#{totals}"
