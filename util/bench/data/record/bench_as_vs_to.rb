
require "benchmark"
require "rubygems" 
require "ruport"  
require "ruport/util/bench"
include Ruport::Bench

class MyFormat < Ruport::Formatter;
  renders :nothing, :for => Ruport::Controller::Row
end

record = Ruport::Data::Record.new [1,2,3]

bench_suite do
  N = 10000   
  bench_case("as(:nothing)",N) { record.as(:nothing) }
  bench_case("to_nothing",N) { record.to_nothing }
end
