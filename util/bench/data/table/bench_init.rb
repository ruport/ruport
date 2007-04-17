require "ruport"
require "enumerator"
require "rubygems"
require "ruport/util/bench"

include Ruport::Bench

deep_data = (0..299).enum_slice(3).to_a

col_names = (0..99).map { |r| r.to_s }
wide_data = (0..299).enum_slice(100).to_a
small_data = [[1,2,3]]
                                 
SMALL_N = 10000
DEEP_N  = 1000
WIDE_N  = 1000
CSV_N   = 100   

bench_suite do   
  
  bench_case("Array#to_table - small table",SMALL_N) {
    small_data.to_table(%w[a b c])
  }

  bench_case("Table.new - small table",SMALL_N) { 
    Ruport::Data::Table.new({:data => small_data,
                             :column_names => %w[a b c]})
  }                    

  bench_case("Table() - small table",SMALL_N) { 
    Table(:data => small_data, :column_names => %w[a b c]) 
  }

  bench_case("Table.new - deep table",DEEP_N) {
    Ruport::Data::Table.new(:data => deep_data, :column_names => %w[a b c])  
  }    

  bench_case("Array#to_table - deep table",DEEP_N) {
    deep_data.to_table(%w[a b c])
  }      

  bench_case("Table.new - wide table",WIDE_N) {
    Ruport::Data::Table.new(:data => wide_data,
                            :column_names => col_names)
  }    

  bench_case("Array#to_table - wide table", WIDE_N) {
    wide_data.to_table(col_names)
  }     

  bench_case("Table() - wide table",WIDE_N) {
    Table(:data => wide_data, :column_names => col_names)
  }       

  bench_case("Table.load - from csv",CSV_N) {
    Ruport::Data::Table.load("util/bench/samples/tattle.csv")
  }  

  data = File.read("util/bench/samples/tattle.csv") 
  bench_case("Table.parse - from csv [preloaded]",CSV_N) {
    Ruport::Data::Table.parse(data)
  } 
                 
  bench_case("FasterCSV Table loading", CSV_N) {
    FasterCSV::Table.new(FasterCSV.read("util/bench/samples/tattle.csv"))
  } 
end 
