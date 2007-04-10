require "ruport"
require "benchmark"

class MyFormat < Ruport::Formatter;
  renders :nothing, :for => Ruport::Renderer::Row
end

record = Ruport::Data::Record.new [1,2,3]

Benchmark.bm do |x|

  N = 10000
  
  x.report("as(:nothing) (x#{N})") do
    N.times { record.as(:nothing) }
  end

  x.report("to_nothing (x#{N})") do
    N.times { record.to_nothing }
  end

end
