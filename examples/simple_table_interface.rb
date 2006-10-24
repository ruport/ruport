require "ruport"
class SimpleTableShortcut < Ruport::Report

  prepare do
    log_file "foo.log"
    @table = table(%w[a b c]) do |t|
      t << [1,2,3]
      t << { "a" => 1, "c" => 9, "b" => 2 }
    end
  end

  generate do
    @table.to_csv
  end

end

SimpleTableShortcut.run(:tries => 3, :interval => 5) { |r| 
  puts r.results
}
