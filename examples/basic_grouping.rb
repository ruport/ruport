require "ruport"
a = [ ['a',7],['b',5],['c',11],
      ['d',9],['a',3],['b',2], ['e',4] ].to_table(%w[letter num])
puts "Initial Data:\n#{a}"


# group by column values
b = a.split(:group => "letter")
totals = [].to_table(%w[group sum])
b.each_group { |x| totals << [x,b[x].sum("num")] }
puts "After column grouping:\n#{totals}"

# group by tag name
a.create_tag_group(:num_even) { |r| (r.num % 2).zero? }
a.create_tag_group(:num_odd)  { |r| (r.num % 2).nonzero? }
c = a.group_by_tag
totals.data.clear
c.each_group { |x| totals << [x,c[x].sum("num")] }
puts "After tag grouping:\n#{totals}"
