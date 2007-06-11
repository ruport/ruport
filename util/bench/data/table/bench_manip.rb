require "ruport"
require "enumerator"
require "rubygems"
require "ruport/util/bench"

include Ruport::Bench  

deep_data = (0..299).enum_slice(3).to_a

col_names = (0..99).map { |r| r.to_s }
wide_data = (0..299).enum_slice(100).to_a

small_table = Table(%w[a b c]) << [1,2,3] << [4,5,6]
deep_table = deep_data.to_table(%w[a b c]) 
wide_table = wide_data.to_table(col_names)

SMALL_N = 5000
DEEP_N  = 1000
WIDE_N  = 1000    

bench_suite do  
           
  bench_case("Table#+ - small table + small table",SMALL_N) {
    small_table + small_table 
  }

  bench_case("Table#+ - small table + deep table",DEEP_N) {
    small_table + deep_table 
  }
          
  bench_case("Table#+ - deep table + deep table",DEEP_N) {
    deep_table + deep_table 
  }       
  
  bench_case("Table#+ - wide table + wide table",WIDE_N) {
    wide_table + wide_table 
  }   
     
  small_table = Table(%w[a b c])     
  bench_case("Table#<< - small array",SMALL_N) {
    small_table << [1,2,3] 
  }                              
  
  small_hash = small_table[0].to_hash
  bench_case("Table#<< - small hash",SMALL_N) {
    small_table << small_hash 
  }       
  
  small_record = small_table[0]
  bench_case("Table#<< - small record",SMALL_N) {
    small_table << small_record 
  }
  
  wide_table = Table(col_names)
  bench_case("Table#<< - large array",WIDE_N) {
    wide_table << wide_data[0] 
  }      
  
  large_hash = wide_table[0].to_hash
  bench_case("Table#<< - large hash",WIDE_N) {
    wide_table << large_hash 
  }       
  
  large_record = wide_table[0]
  bench_case("Table#<< - large record",WIDE_N) {
    wide_table << large_record 
  }  
  
  small_table = Table(%w[a b c]) << [1,2,3] << [4,5,6]
  deep_table = deep_data.to_table(%w[a b c]) 
  wide_table = wide_data.to_table(col_names)  

  bench_case("Table#rows_with - one arg",SMALL_N) {
    deep_table.rows_with("a") { |a| a < 100 } 
  }            

  bench_case("Table#rows_with - array arg",SMALL_N) {
    deep_table.rows_with(%w[a b]) { |a,b| a < 100 || b > 200 } 
  }
      
  bench_case("Table#sigma - column_name",SMALL_N) {
    deep_table.sigma("a") 
  }                  

  bench_case("Table#sigma - simple block",SMALL_N) {
    deep_table.sigma { |r| r.a } 
  }  
  
  bench_case("Table#sub_table - small table",WIDE_N) {
    small_table.sub_table(%w[a c],1..-1)
  }   
                         
  cols = wide_table.column_names.sort_by { rand }[0..49]
  bench_case("Table#sub_table - wide table",WIDE_N) {
    wide_table.sub_table(cols,1..-1)
  }          
  
  bench_case("Table#sub_table - deep table",DEEP_N) {
    deep_table.sub_table(%w[c a]) { |r| r.a < 100 or r.b > 200 }
  }           
  
  bench_case("Table#sort_rows_by(one arg) - small table",SMALL_N) {
    small_table.sort_rows_by("a")
  }
        
  bench_case("Table#sort_rows_by(one arg) - deep table",DEEP_N) {
    deep_table.sort_rows_by("a")
  }
    
  bench_case("Table#sort_rows_by(array arg) - small table",SMALL_N) {
    small_table.sort_rows_by(%w[a c])
  }
        
  bench_case("Table#sort_rows_by(array arg) - deep table",DEEP_N) {
    deep_table.sort_rows_by(%w[a c])
  }                               
  bench_case("Table#sort_rows_by block - small table",SMALL_N) {
    small_table.sort_rows_by { |r| r.a + r.c }
  }
        
  bench_case("Table#sort_rows_by block - deep table",DEEP_N) {
    deep_table.sort_rows_by { |r| r.a + r.c } 
  }
    
end
