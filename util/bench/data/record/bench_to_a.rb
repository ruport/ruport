require "ruport"
require "benchmark"

large = (1..1000).to_a
large_attributes = large.map { |e| e.to_s.reverse }

large_record = Ruport::Data::Record.new(large,
                                        :attributes => large_attributes)

small_record = Ruport::Data::Record.new([1,2,3],
                                        :attributes => %w[a b c])

Benchmark.bm do |x|
  SMALL_N = 100000
  LARGE_N = 1000
  x.report("to_a : Large Record (x#{LARGE_N})") {
    LARGE_N.times { large_record.to_a }
  }
  x.report("to_a: Small Record (x#{SMALL_N})") {
    SMALL_N.times { small_record.to_a }
  }
end
