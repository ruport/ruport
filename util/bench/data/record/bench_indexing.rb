require "ruport"
require "rubygems"
require "ruport/util/bench"
include Ruport::Bench

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

SMALL_N = 10000
LARGE_N = 10

bench_suite do

  bench_case("Integer Index - Small",SMALL_N) {
    (0..2).each { |i| small_record[i] } 
  }

  bench_case("Integer Index - Large",LARGE_N) {  
     large.each_index { |r| large_record[r]  }
  }

  bench_case("String Index - Small", SMALL_N) {
    small_attributes.each { |a| small_record[a] }
  }

  bench_case("String Index - Large", LARGE_N) {    
    large_attributes.each { |a| large_record[a] }
  }

  bench_case("Integer get() - Small", SMALL_N) {
    (0..2).each { |i| small_record.get(i) } 
  }

  bench_case("Integer get() - Large", LARGE_N) {  
    large.each_index { |r| large_record.get(r) } 
  }

  bench_case("String get() - Small", SMALL_N) {
    small_attributes.each { |a| small_record.get(a) }
  }

  bench_case("String get() - Large", LARGE_N) {     
    large_attributes.each { |a| large_record.get(a) }
  }

  bench_case("Symbol get() - Small", SMALL_N) {    
    sym_s_attributes.each { |a| small_record.get(a) }
  }

  bench_case("Symbol get() - Large", LARGE_N) {  
    sym_l_attributes.each { |a| large_record.get(a) }
  }

end
