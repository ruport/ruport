#!/usr/bin/env ruby -w   
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")    

class DataFeederTest < Test::Unit::TestCase
   
  context "when using a default data feeder" do
      
    def setup
      @feeder = Ruport::Data::Feeder.new(Table(%w[a b c]))      
    end    
    
    def specify_data_attribute_should_return_wrapped_data
      assert_equal Table(%w[a b c]), @feeder.data  
    end
     
    def specify_append_should_forward_to_wrapped_data_by_default
      t = Table(%w[a b c])
      t << [1,2,3] << {"a" => 2, "b" => 3, "c" => 4}
      @feeder << [1,2,3] << {"a" => 2, "b" => 3, "c" => 4} 
      assert_equal t, @feeder.data 
    end  
    
  end 
  
  context "when using a feeder with a filter" do
     def setup 
       @feeder = Ruport::Data::Feeder.new(Table(%w[a b c]))
       @feeder.filter { |r| r.a != 1 }
     end    
     
     def specify_filter_should_only_append_rows_for_which_block_is_true
       @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5]
       assert_equal Table(%w[a b c], :data => [[4,1,2],[3,1,1]]), @feeder.data  
     end
  end 
  
  context "when using a feeder with a transform" do
     def setup
       @feeder = Ruport::Data::Feeder.new(Table(%w[a b c])) 
       @feeder.transform { |r| r.a += 1 }
     end
     
     def specify_filter_should_be_applied_to_all_rows
       @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5]
       assert_equal Table(%w[a b c], :data => [[2,2,3],[5,1,2],[4,1,1],[2,2,5]]),
                    @feeder.data
     end     
  end  
  
  context "when using a feeder and a filter together" do
    def setup
      @feeder = Ruport::Data::Feeder.new(Table(%w[a b c]))
    end 
    
    def specify_filter_is_called_first_when_defined_first
      @feeder.filter { |r| r.b != 2 }
      @feeder.transform { |r| r.b += 1 }
      @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5] 
      assert_equal Table(%w[a b c], :data => [[4,2,2],[3,2,1]]),
                   @feeder.data
    end
    
    def specify_transform_is_called_first_when_defined_first
      @feeder.transform { |r| r.b += 1 }                    
      @feeder.filter { |r| r.b != 2 }      
      @feeder << [1,2,3] << [4,1,2] << [3,1,1] << [1,2,5] 
      assert_equal Table(%w[a b c], :data => [[1,3,3],[1,3,5]]),
                   @feeder.data
    end 
  end      
  
  context "when using many feeders and filters together" do
    def setup
      @feeder = Ruport::Data::Feeder.new(Table(%w[a b c])) 
      @feeder.transform { |r| r.a += 1 }      
      @feeder.filter { |r| r.a > 5 }
      @feeder.transform { |r| r.b = r.b.to_s } 
      @feeder.filter { |r| r.b == "3" } 
   end
   
   def specify_all_blocks_are_executed_in_order
     @feeder << [1,2,3] << [4,1,9] << [5,3,1] << [2,3,0] << [7,3,5] 
     assert_equal Table(%w[a b c], :data => [[6,"3",1],[8,"3",5]]),
                  @feeder.data
   end  
 end
  
end