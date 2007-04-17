require "ruport"
require "enumerator"
require "rubygems"
require "ruport/util/bench"
include Ruport::Bench

source = Ruport::Data::Table.load("util/bench/samples/tattle.csv")

N = 1
bench_suite do  
 bench_case("Basic PDF table output", N) {
   source.to_pdf
 }
end