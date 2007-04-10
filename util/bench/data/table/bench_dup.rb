require "ruport"
require "benchmark"
require "enumerator"


deep_data = (0..299).enum_slice(3).to_a

col_names = (0..99).map { |r| r.to_s }
wide_data = (0..299).enum_slice(100).to_a

small_table = Table(%w[a b c]) << [1,2,3] << [4,5,6]
deep_table = deep_data.to_table(%w[a b c]) 
wide_table = wide_data.to_table(col_names)

Benchmark.bm do |x|
  SMALL_N = 1000
  DEEP_N  = 100
  WIDE_N  = 100

  x.report("Table#dup - small table (x#{SMALL_N})") {
    SMALL_N.times { small_table.dup }
  }

  x.report("Table#dup - deep table (x#{DEEP_N})") {
    DEEP_N.times { deep_table.dup }
  }

  x.report("Table#dup - wide table (x#{WIDE_N})") {
    WIDE_N.times { wide_table.dup }
  }
end
