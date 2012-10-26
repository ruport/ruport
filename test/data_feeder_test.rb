#!/usr/bin/env ruby -w   
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")    

class DataFeederTest < Test::Unit::TestCase
   
  context "when using a default data feeder" do
      
    setup do
      @feeder = Ruport::Data::Feeder.new(Table(%w[a b c]))      
    end    
    
    should "data attribute should return wrapped data" do
      assert_equal Table(%w[a b c]), @feeder.data  
    end
     
    should "append should forward to wrapped data by default" do
      t = Table(%w[a b c])
      t << [1,2,3] << {"a" => 2, "b" => 3, "c" => 4}
      @feeder << [1,2,3] << {"a" => 2, "b" => 3, "c" => 4} 
      assert_equal t, @feeder.data 
    end  
    
  end 
  
  context "when using a feeder with a filter" do
     setup do 
       @feeder = Ruport::Data::Feeder.new(Table(%w[a b c]))
       @feeder.filter { |r| r.a != 1 }
     end    
     
     should "filter should only append rows for which block is true" do
       @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5]
       assert_equal Table(%w[a b c], :data => [[4,1,2],[3,1,1]]), @feeder.data  
     end
  end 
  
  context "when using a feeder with a transform" do
     setup do
       @feeder = Ruport::Data::Feeder.new(Table(%w[a b c])) 
       @feeder.transform { |r| r.a += 1 }
     end
     
     should "filter should be applied to all rows" do
       @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5]
       assert_equal Table(%w[a b c], :data => [[2,2,3],[5,1,2],[4,1,1],[2,2,5]]),
                    @feeder.data
     end     
  end  
  
  context "when using a feeder and a filter together" do
    setup do
      @feeder = Ruport::Data::Feeder.new(Table(%w[a b c]))
    end 
    
    should "filter is called first when defined first" do
      @feeder.filter { |r| r.b != 2 }
      @feeder.transform { |r| r.b += 1 }
      @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5] 
      assert_equal Table(%w[a b c], :data => [[4,2,2],[3,2,1]]),
                   @feeder.data
    end
    
    should "transform is called first when defined first" do
      @feeder.transform { |r| r.b += 1 }                    
      @feeder.filter { |r| r.b != 2 }      
      @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5] 
      assert_equal Table(%w[a b c], :data => [[1,3,3],[1,3,5]]),
                   @feeder.data
    end 
  end      
  
  context "when using many feeders and filters together" do
    setup do
      @feeder = Ruport::Data::Feeder.new(Table(%w[a b c])) 
      @feeder.transform { |r| r.a += 1 }      
      @feeder.filter { |r| r.a > 5 }
      @feeder.transform { |r| r.b = r.b.to_s } 
      @feeder.filter { |r| r.b == "3" } 
   end
   
   should "all blocks are executed in order" do
     @feeder << [1,2,3] << [4,1,9] << [5,3,1] << [2,3,0] << [7,3,5] 
     assert_equal Table(%w[a b c], :data => [[6,"3",1],[8,"3",5]]),
                  @feeder.data
   end  
 end
  
end
