require "ruport"
require "benchmark"

large = (1..1000).to_a
large_attributes = large.map { |e| e.to_s.reverse }

large_hash = large.inject({}) do |s,r|
  s.merge(r-1 => r)
end

la = large_hash.keys.sort_by { rand }

Benchmark.bm do |x|
  SMALL_N = 10000
  LARGE_N = 10
  x.report("Array - No Attributes - Small ") { 
   SMALL_N.times { Ruport::Data::Record.new [1,2,3] }
  }
  x.report("Array w. Attributes   - Small ") { 
   SMALL_N.times { Ruport::Data::Record.new [1,2,3], 
                    :attributes => %w[a b c] }
  }
  x.report("Array - No Attributes - Large ") {  
    LARGE_N.times { Ruport::Data::Record.new large }
  }
  x.report("Array w. Attributes   - Large ") {  
    LARGE_N.times { Ruport::Data::Record.new large,
                     :attributes => large_attributes }
  }
  x.report("Hash  - No Attributes - Small ") {  
    SMALL_N.times do
      Ruport::Data::Record.new({ 0 => 1, 1 => 2, 2 => 3 }) 
    end
  }
  x.report("Hash w. Attributes   - Small ") {  
    SMALL_N.times do
      Ruport::Data::Record.new({"a" => 1, "b" => 2, "c" => 3}, 
                               :attributes => %w[a b c])
    end
  }
  x.report("Hash - No Attributes - Large ") {  
    LARGE_N.times { Ruport::Data::Record.new(large_hash) }
  }
  x.report("Hash w. Attributes   - Large ") {  
    LARGE_N.times { Ruport::Data::Record.new(large_hash, 
                    :attributes => la ) }
  
  }

end
