require "ruport"
require "benchmark"
require "rubygems"
require "ruport/util/bench"
include Ruport::Bench

large = (1..1000).to_a
large_attributes = large.map { |e| e.to_s.reverse }

large_hash = large.inject({}) do |s,r|
  s.merge(r-1 => r)
end

la = large_hash.keys.sort_by { rand }
SMALL_N = 10000
LARGE_N = 10

bench_suite do

  bench_case("Array - No Attributes",SMALL_N) { 
    Ruport::Data::Record.new [1,2,3] 
  }
  bench_case("Array w. Attributes - Small",SMALL_N) { 
    Ruport::Data::Record.new [1,2,3], :attributes => %w[a b c]     
  }
  bench_case("Array - No Attributes - Large",LARGE_N) {  
    Ruport::Data::Record.new large 
  }
  bench_case("Array w. Attributes   - Large",LARGE_N) {  
    Ruport::Data::Record.new large, :attributes => large_attributes 
  }
  bench_case("Hash  - No Attributes - Small", SMALL_N) {  
    Ruport::Data::Record.new({ 0 => 1, 1 => 2, 2 => 3 })
  }
  bench_case("Hash w. Attributes   - Small",SMALL_N) {  
    Ruport::Data::Record.new({"a" => 1, "b" => 2, "c" => 3}, 
                             :attributes => %w[a b c]) 
  }
  bench_case("Hash - No Attributes - Large",LARGE_N) {  
    Ruport::Data::Record.new(large_hash) 
  }
  bench_case("Hash w. Attributes   - Large",LARGE_N) {  
    Ruport::Data::Record.new(large_hash, :attributes => la )  
  }

end
