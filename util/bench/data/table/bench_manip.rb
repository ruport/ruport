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

  x.report("Table#+ - small table + small table (x#{SMALL_N})") {
    SMALL_N.times { small_table + small_table }
  }      
  
  x.report("Table#+ - small table + deep table (x#{DEEP_N})") {
    DEEP_N.times { small_table + deep_table }
  }
          
  x.report("Table#+ - deep table + deep table (x#{DEEP_N})") {
    DEEP_N.times { deep_table + deep_table }
  }       
  
  x.report("Table#+ - wide table + wide table (x#{WIDE_N})") {
    WIDE_N.times { wide_table + wide_table }
  }   
     
  small_table = Table(%w[a b c]) 
  x.report("Table#<< - small array (x#{SMALL_N})") {
    SMALL_N.times {  small_table << [1,2,3] }
  }                              
  
  small_hash = small_table[0].to_h
  x.report("Table#<< - small hash (x#{SMALL_N})") {
    SMALL_N.times { small_table << small_hash }
  }       
  
  small_record = small_table[0]
  x.report("Table#<< - small record (x#{SMALL_N})") {
    SMALL_N.times { small_table << small_record }
  }
  
  wide_table = Table(col_names)
  x.report("Table#<< - large array (x#{WIDE_N})") {
    WIDE_N.times { wide_table << wide_data[0] }
  }      
  
  large_hash = wide_table[0].to_h
  x.report("Table#<< - large hash (x#{WIDE_N})") {
    WIDE_N.times { wide_table << large_hash }
  }       
  
  large_record = wide_table[0]
  x.report("Table#<< - large record (x#{WIDE_N})") {
    WIDE_N.times { wide_table << large_record }
  }    
  
  x.report("Table#rows_with - one arg (x#{SMALL_N})") {
    SMALL_N.times { deep_table.rows_with("a") { |a| a < 100 } }
  }            
  
  x.report("Table#rows_with - array arg (x#{SMALL_N})") {
    SMALL_N.times { deep_table.rows_with(%w[a b]) { |a,b| a < 100 || b > 200 } }
  }
      
  x.report("Table#sigma - column_name (x#{SMALL_N})") {
    SMALL_N.times { puts deep_table.sigma("a") }
  }                  
  
  x.report("Table#sigma - simple block (x#{SMALL_N})") {
    SMALL_N.times { puts deep_table.sigma { |r| r.a } }
  }

end