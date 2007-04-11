require "ruport"
require "benchmark"
require "enumerator"
require "rubygems"

deep_data = (0..299).enum_slice(3).to_a

col_names = (0..99).map { |r| r.to_s }
wide_data = (0..299).enum_slice(100).to_a
small_data = [[1,2,3]]

Benchmark.bm do |x|
  SMALL_N = 1000
  DEEP_N  = 100
  WIDE_N  = 100
  CSV_N   = 10

  x.report("Table.new - small table (x#{SMALL_N})") { 
    SMALL_N.times { Ruport::Data::Table.new(:data => small_data,
                                            :column_names => %w[a b c])
    }
  }

  x.report("Table.new - deep table (x#{DEEP_N})") {
    DEEP_N.times { Ruport::Data::Table.new(:data => deep_data,
                                           :column_names => %w[a b c]) }
  }

  x.report("Table.new - wide table (x#{WIDE_N})") {
    WIDE_N.times { Ruport::Data::Table.new(:data => wide_data,
                                            :column_names => col_names) }
  }

  x.report("Table.load - from csv (x#{CSV_N})") {
    CSV_N.times { Ruport::Data::Table.load("util/bench/samples/tattle.csv") }
  }

  x.report("FasterCSV Table loading (x#{CSV_N})") {
    CSV_N.times { FasterCSV::Table.new(
                    FasterCSV.read("util/bench/samples/tattle.csv")) } 
  }
end
