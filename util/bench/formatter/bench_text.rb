require "ruport"
require "enumerator"
require "rubygems"
require "ruport/util/bench"
include Ruport::Bench

source = Ruport::Data::Table.load("util/bench/samples/tattle.csv")

N = 2
bench_suite do  
 bench_case("Basic Text table output", N) {
   source.to_text
 }
end