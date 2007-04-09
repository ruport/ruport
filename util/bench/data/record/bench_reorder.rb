require "ruport"
require "benchmark"

large = (1..1000).to_a
large_attributes = large.map { |e| e.to_s.reverse }

rand_large_attributes = large_attributes.sort_by { rand }


large_record = Ruport::Data::Record.new large,
               :attributes => large_attributes

small_record = Ruport::Data::Record.new({ "foo"  => 'bar', 
                                           "baz"  => "bang",
                                           "Quux" => "adfdsa" })

rand_small_attributes = small_record.attributes.sort_by { rand }

Benchmark.bm do |x|
  SMALL_N = 10000
  LARGE_N = 100

  x.report("reorder - small") {
    SMALL_N.times do
      record = small_record.dup
      record.reorder(rand_small_attributes)
    end
  }
  x.report("reorder - large") {
    LARGE_N.times do
      record = large_record.dup
      record.reorder(rand_large_attributes)
    end
  }

end
