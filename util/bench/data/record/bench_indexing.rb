require "ruport"
require "benchmark"

large = (1..1000).to_a
large_attributes = large.map { |e| e.to_s.reverse }
sym_l_attributes = large_attributes.map { |r| r.intern }

large_record = Ruport::Data::Record.new large,
               :attributes => large_attributes

small_record = Ruport::Data::Record.new({ "foo"  => 'bar', 
                                           "baz"  => "bang",
                                           "Quux" => "adfdsa" })

small_attributes = small_record.attributes
sym_s_attributes = small_attributes.map { |r| r.intern }

Benchmark.bm do |x|
  SMALL_N = 10000
  LARGE_N = 10

  x.report("Integer Index - Small (x#{SMALL_N})") {
    SMALL_N.times { (0..2).each { |i| small_record[i] } }
  }

  x.report("Integer Index - Large (x#{LARGE_N})") {  
    LARGE_N.times { large.each_index { |r| large_record[r] } }
  }

  x.report("String Index - Small (x#{SMALL_N})") {
    SMALL_N.times { 
      small_attributes.each { |a|
         small_record[a]
      }
    }
  }

  x.report("String Index - Large (x#{LARGE_N})") {
    LARGE_N.times { 
      large_attributes.each { |a|
         large_record[a]
      }
    }
  }

  x.report("Integer get() - Small (x#{SMALL_N})") {
    SMALL_N.times { (0..2).each { |i| small_record.get(i) } }
  }

  x.report("Integer get() - Large (x#{LARGE_N})") {  
    LARGE_N.times { large.each_index { |r| large_record.get(r) } }
  }

  x.report("String get() - Small (x#{SMALL_N})") {
    SMALL_N.times { 
      small_attributes.each { |a|
         small_record.get(a)
      }
    }
  }

  x.report("String get() - Large (x#{LARGE_N})") {
    LARGE_N.times { 
      large_attributes.each { |a|
         large_record.get(a)
      }
    }
  }

  x.report("Symbol get() - Small (x#{SMALL_N})") {
    SMALL_N.times { 
      sym_s_attributes.each { |a|
         small_record.get(a)
      }
    }
  }

  x.report("Symbol get() - Large (x#{LARGE_N})") {
    LARGE_N.times { 
      sym_l_attributes.each { |a|
         large_record.get(a)
      }
    }
  }

end
