require "ruport"
require "enumerator"
require "rubygems"
require "ruport/util/bench"

include Ruport::Bench  

deep_data = (0..299).enum_slice(3).to_a

col_names = (0..99).map { |r| r.to_s }
wide_data = (0..299).enum_slice(100).to_a

small_table = Table() << [1,2,3] << [4,5,6]
deep_table = deep_data.to_table
wide_table = wide_data.to_table

SMALL_N = 5000
DEEP_N  = 500
WIDE_N  = 500    

bench_suite do  

  bench_prepare { @table = small_table.dup }
  bench_case("Table#column_names= small table",SMALL_N) {
    @table.column_names = %w[a b c]
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#column_names= deep table",DEEP_N) {
    @table.column_names = %w[a b c]
  }

  bench_prepare { @table = wide_table.dup }
  bench_case("Table#column_names= wide table",WIDE_N) {
    @table.column_names = col_names
  }

  small_table = Table(%w[a b c]) << [1,2,3] << [4,5,6]
  deep_table = deep_data.to_table(%w[a b c])
  wide_table = wide_data.to_table(col_names)

  bench_prepare { @table = small_table.dup }
  bench_case("Table#reorder small table",SMALL_N) {
    @table.reorder(%w[c a b])
  }

  bench_prepare { @table = small_table.dup }
  bench_case("Table#reorder small table - by ordinal",SMALL_N) {
    @table.reorder(2,0,1)
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#reorder deep table",DEEP_N) {
    @table.reorder(%w[c a b])
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#reorder deep table - by ordinal",DEEP_N) {
    @table.reorder(2,0,1)
  }

  cols  = col_names.sort_by { rand }
  bench_prepare { @table = wide_table.dup }
  bench_case("Table#reorder wide table",WIDE_N) {
    @table.reorder(cols)
  }

  cols  = col_names.sort_by { rand }.map { |e| e.to_i }
  bench_prepare { @table = wide_table.dup }
  bench_case("Table#reorder wide table - by ordinal",WIDE_N) {
    @table.reorder(cols)
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#swap_column",DEEP_N) {
    @table.swap_column("a","c")
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#swap_column - ordinal",DEEP_N) {
    @table.swap_column(2,0)
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#replace_column",DEEP_N) {
    @table.replace_column("a") { |r| r.b - r.a }
  }

  bench_case("Table#column - by name", DEEP_N) {
    deep_table.column("a")
  }

  bench_case("Table#column - by index", DEEP_N) {
    deep_table.column(0)
  }

  bench_prepare { @table = deep_table.dup }
  bench_case("Table#add_column",DEEP_N) {
    @table.add_column("d") { |r| r.a + r.b }
  }
 

end
