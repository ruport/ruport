#!/usr/bin/env ruby -w 
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")
TEST_SAMPLES = File.join(File.expand_path(File.dirname(__FILE__)), "samples")

class Person < Ruport::Data::Record
  
  def name
    first_name + " " + last_name
  end

end      

class DuckRecord < Ruport::Data::Record; end

class TestTable < Test::Unit::TestCase
  def test_constructors
    table  = Ruport::Data::Table.new

    table2 = Ruport::Data::Table.new :column_names => %w[a b c]
    table3 = Ruport::Data::Table.new :data => [[1,2,3]]
    table4 = Ruport::Data::Table.new :column_names => %w[col1 col2 col3], 
                                     :data => [[1,2,3]]
    tables = [table,table2,table3,table4]

    tables.zip([[],%w[a b c], [], %w[col1 col2 col3]]).each do |t,n|
      assert_equal n, t.column_names

      t = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
      table_from_records = Table(t.column_names, :data => t.data)
    end
    
    a = Ruport::Data::Record.new [1,2,3]
    b = Ruport::Data::Record.new [1,2,3], :attributes => %w[col1 col2 col3]
    tables.zip([[],[],[a],[b]]).each do |t,n| 
      assert_equal n, t.data 
    end
  end    

  context "when filtering data" do

    def setup
      @data = [[1,2,3],[4,5,6],[7,8,9]]
    end

    def specify_filters_should_discard_unmatched_rows
      table = Ruport::Data::Table.new(:column_names => %w[a b c],
                                      :data => [[1,2,3],[4,5,6],[7,8,9]],
                                      :filters => [ lambda { |r| r.a % 2 == 1 } ] )
      assert_equal Table(%w[a b c]) << [1,2,3] << [7,8,9], table
    end     
    
    def specify_filters_should_work_on_csvs        
      only_ids_less_than_3 = lambda { |r| r["id"].to_i < 3 }
      table = Table(File.join(TEST_SAMPLES,"addressbook.csv"), 
                    :filters => [only_ids_less_than_3])
      assert_equal ["1","2"], table.map { |r| r["id"] }
    end
  end  
  
  context "when transforming data" do
    
    def setup
      @data = [[1,2,3],[4,5,6],[7,8,9]] 
    end
    
    def specify_transforms_should_modify_table_data
     
     stringify_c = lambda { |r| r.c = r.c.to_s } 
     add_two_to_all_int_cols = lambda { |r|
      r.each_with_index do |c,i|
        if Fixnum === c
          r[i] += 2
        end
      end
        
     }                                                           
     
     table = Ruport::Data::Table.new(:column_names => %w[a b c],
                                     :data => @data,
                                     :transforms => [stringify_c,
                                                     add_two_to_all_int_cols])
     assert_equal Table(%w[a b c]) << [3,4,"3"] << [6,7,"6"] << [9,10,"9"],
                  table
      
    end 
    
    def specify_transforms_should_work_on_csvs  
      ids_to_i = lambda { |r| r["id"] = r["id"].to_i }
      table = Table(File.join(TEST_SAMPLES,"addressbook.csv"), 
                    :filters => [ids_to_i])  
      assert_equal [1,2,3,4,5], table.map { |r| r["id"] }          
    end
  end

  def test_to_group
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]]).to_group("Packrats")
    b = Ruport::Data::Group.new( :data => [[1,2,3],[4,5,6]],
                                 :column_names => %w[a b c],
                                 :name => "Packrats" )
    assert_equal a,b
  end
 
  def test_rows_with
    table = Table(%w[a b c], :data => [[1,2,3],[1,3,4],[7,8,9]])
    
    assert_equal([table[0],table[1]],table.rows_with("a" => 1))
    assert_equal([table[1]],table.rows_with("a" => 1, "b" => 3))
    assert_equal([table[0]],table.rows_with(:a => 1, :b => 2))
    assert_equal([table[2]], table.rows_with_b(8))
    assert_equal [table[1]], table.rows_with(%w[a b]) { |a,b| [a,b] == [1,3] }
  end
  
  def test_sigma
    table = Table(%w[col1 col2], :data => [[1,2],[3,4],[5,6]])
    assert table.respond_to?(:sigma)
    assert table.respond_to?(:sum)
    assert_equal(9,table.sigma(0))
    assert_equal(9,table.sigma("col1"))
    assert_equal(21,table.sigma { |r| r.col1 + r.col2 })
  end
  
  def test_sub_table
    table = Table(%w[a b c d], 
      :data => [ [1,2,3,4],[5,6,7,9],[10,11,12,13],[14,15,16,17] ])
   
    assert_equal Table(%w[b c], :data => [[6,7],[11,12]]), 
                 table.sub_table(%w[b c],1..-2) 
                 
    assert_equal Table(%w[c d a], :data => [[3,4,1],[7,9,5]]),  
                 table.sub_table(%w[c d a]) { |r| r.a < 10 }    
                 
    assert_equal Table(%w[a c], :data => [[1,3],[5,7],[10,12],[14,16]]),  
                 table.sub_table(%w[a c])
     
    assert_equal Table(%w[a b c d], :data => [[10,11,12,13],[14,15,16,17]]),      
                 table.sub_table { |r| r.c > 10 }      
                 
    assert_equal Table(%w[a b c d], :data => [[10,11,12,13],[14,15,16,17]]),      
                table.sub_table(2..-1)   
                  
  end
  
  def test_subtable_records_have_correct_data
    table = Table(%w[a b c d],
      :data => [ [1,2,3,4],[5,6,7,9],[10,11,12,13],[14,15,16,17] ])
    sub = table.sub_table(%w[b c d]) {|r| r.a == 1 }
    assert_equal({"b"=>2, "c"=>3, "d"=>4}, sub[0].data)
    assert_equal(["b", "c", "d"], sub[0].attributes)
  end

  def test_reduce
    table = Table(%w[a b c d],
      :data => [ [1,2,3,4],[5,6,7,9],[10,11,12,13],[14,15,16,17] ])

    table.reduce(%w[b c],1..-2)
    assert_equal Table(%w[b c], :data => [[6,7],[11,12]]), table

    table = Table(%w[a b c d],
      :data => [ [1,2,3,4],[5,6,7,9],[10,11,12,13],[14,15,16,17] ])
    table.reduce(%w[c d a]) { |r| r.a < 10 }

    assert_equal Table(%w[c d a], :data => [[3,4,1],[7,9,5]]), table
  end

  def test_reorder
    table = Ruport::Data::Table.load(File.join(TEST_SAMPLES,"data.csv"))
    table.reorder(*%w[col1 col3])
    assert_equal %w[col1 col3], table.column_names
    rows = [%w[a c], %w[d e]]
    table.each { |r| assert_equal rows.shift, r.to_a
                     assert_equal %w[col1 col3], r.attributes }
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]]).reorder 2,0
    rows = [[3,1],[6,4]]
    a.each { |r| assert_equal rows.shift, r.to_a 
                 assert_equal %w[c a], r.attributes }
    assert_equal %w[c a], a.column_names

    b = Table(%w[a b c], :data => [[1,2,3],[4,5,6]]).reorder(%w[a c])
    rows = [[1,3],[4,6]]
    b.each { |r| 
      assert_equal rows.shift, r.to_a
      assert_equal %w[a c], r.attributes 
      assert_equal b.column_names.object_id,
                   r.instance_eval{@attributes}.object_id
    }
  end     
  
  context "when sorting rows" do 
    
    def setup
      @table = Table(%w[a b c]) << [1,2,3] << [6,1,8] << [9,1,4] 
      @table_with_nils = Table(%w[a b c]) << [1,nil,3] << [9,3,4] << [6,1,8]
    end
    
    def specify_should_sort_in_reverse_order_on_descending
       t = @table.sort_rows_by("a", :order => :descending ) 
       assert_equal Table(%w[a b c]) << [9,1,4] << [6,1,8] << [1,2,3], t   
       
       t = @table.sort_rows_by("c", :order => :descending ) 
       assert_equal Table(%w[a b c]) << [6,1,8] << [9,1,4] << [1,2,3], t               
    end  
    
    def specify_show_put_rows_with_nil_columns_after_sorted_rows    
       # should not effect when using columns that are all populated
       t = @table_with_nils.sort_rows_by("a") 
       assert_equal Table(%w[a b c]) << [1,nil,3] << [6,1,8] << [9,3,4], t 
       
       t = @table_with_nils.sort_rows_by("b")
       assert_equal Table(%w[a b c]) << [6,1,8] << [9,3,4] << [1,nil,3], t    
       
       t = @table_with_nils.sort_rows_by("b", :order => :descending)
       assert_equal Table(%w[a b c]) << [1,nil,3] << [9,3,4] << [6,1,8], t
    end
    
    def specify_in_place_sort_should_allow_order_by
       @table.sort_rows_by!("a", :order => :descending )
       assert_equal Table(%w[a b c]) << [9,1,4] << [6,1,8] << [1,2,3], @table
    end
    
    def specify_sort_rows_by
      table = Ruport::Data::Table.new :column_names => %w[a b c]
      table << [1,2,3] << [6,1,8] << [9,1,4]    
    
      table2 = Ruport::Data::Table.new :column_names => [:a, :b, :c]
      table2 << [1,2,3] << [6,1,8] << [9,1,4]

      sorted_table_a = Ruport::Data::Table.new :column_names => %w[a b c]
      sorted_table_a << [1,2,3] << [6,1,8] << [9,1,4]

      sorted_table_b = Ruport::Data::Table.new :column_names => %w[a b c]
      sorted_table_b << [6,1,8] << [9,1,4] << [1,2,3]
    
      sorted_table_bc = Ruport::Data::Table.new :column_names => %w[a b c]
      sorted_table_bc << [9,1,4] << [6,1,8] << [1,2,3] 
    
      sorted_table_bs = Ruport::Data::Table.new :column_names => [:a, :b, :c]
      sorted_table_bs << [6,1,8] << [9,1,4] << [1,2,3]
  
      assert_equal sorted_table_a,  table.sort_rows_by {|r| r['a']}
      assert_equal sorted_table_b,  table.sort_rows_by(['b'])
      assert_equal sorted_table_bc, table.sort_rows_by(['b', 'c'])
      assert_equal sorted_table_bs, table2.sort_rows_by(:b)
    end              
       
    def specify_sort_rows_by!
      table = Ruport::Data::Table.new :column_names => %w[a b c]
      table << [1,2,3] << [6,1,8] << [9,1,4]

      sorted_table_a = Ruport::Data::Table.new :column_names => %w[a b c]
      sorted_table_a << [1,2,3] << [6,1,8] << [9,1,4]

      sorted_table_b = Ruport::Data::Table.new :column_names => %w[a b c]
      sorted_table_b << [6,1,8] << [9,1,4] << [1,2,3]
    
      sorted_table_bc = Ruport::Data::Table.new :column_names => %w[a b c]
      sorted_table_bc << [9,1,4] << [6,1,8] << [1,2,3]
    
      table_a = table.dup
      table_a.sort_rows_by! { |r| r['a'] }       
    
      table_b = table.dup
      table_b.sort_rows_by!("b")
    
      table_bc = table.dup
      table_bc.sort_rows_by!(['b', 'c'])             
  
      assert_equal sorted_table_a,  table_a
      assert_equal sorted_table_b,  table_b
      assert_equal sorted_table_bc, table_bc
    end
    
  end  

  def test_record_class
    a = Ruport::Data::Table.new( :column_names => %w[first_name last_name c], 
                                 :data =>[['joe','loop',3],['jim','blue',6]],
                                 :record_class => Person )
    assert_equal a, Table(%w[first_name last_name c],
      :data => [ ['joe','loop',3],['jim','blue',6] ])
    assert_kind_of Person, a[0]
    assert_equal 'joe loop', a[0].name
    assert_equal 'jim blue', a[1].name

    b = Table(%w[first_name last_name], :record_class => Person) do |t|
      t << { 'first_name' => 'joe', 'last_name' => 'frasier' }
      t << { 'first_name' => 'brian', 'last_name' => 'black' }
    end

    b.each { |r| assert_kind_of Person, r }

    assert_equal ['joe frasier', 'brian black'], b.map { |r| r.name }
  end 

  ## BUG Traps -------------------------------------------------
  
  def test_ensure_table_creation_allows_record_coercion
    table = Table([], :data => [[1,2,3],[4,5,6],[7,8,9]])
    table_with_names = Table(%w[a b c], :data => [[1,2,3],[4,5,6],[7,8,9]])
   
    a,b,c = nil
    assert_nothing_raised { a = Table(%w[a b c], :data => table.to_a) }
    assert_nothing_raised { b = Table(%w[d e f], :data => table.to_a) }
    assert_nothing_raised { c = Table(table_with_names.column_names,
      :data => table_with_names.to_a) }

    [a,b,c].each { |t| assert_equal(3,t.length) }
    assert_equal %w[a b c], a.column_names
    a.each { |r|
      assert_equal %w[a b c], r.attributes
      assert_nothing_raised { r.a; r.b; r.c }
      [r.a,r.b,r.c].each { |i| assert(i.kind_of?(Numeric)) }
    }
    assert_equal %w[d e f], b.column_names
    b.each { |r|
      assert_equal %w[d e f], r.attributes
      assert_nothing_raised { r.d; r.e; r.f }
      [r.d,r.e,r.f].each { |i| assert(i.kind_of?(Numeric)) }
    }
    c.each { |r|
      assert_nothing_raised { r[0]; r[1]; r[2] }
      [r[0],r[1],r[2]].each { |i| assert(i.kind_of?(Numeric)) }
    }
  end   
  
  def test_ensure_coerce_sum
    s = Table([], :data => [["1"],["3"],["5"]])
    t = Table([], :data => [["1.23"],["1.5"]])
    
    assert_equal(9,s.sum(0))
    assert_equal(2.73,t.sum(0))
  end
  
  def test_to_yaml
    require "yaml"
    a = Table([])
    assert_nothing_raised { a.to_yaml }
    a = Table(%w[first_name last_name],:record_class => Person) { |t| 
      t << %w[joe loop] 
    }
    assert_equal "joe loop", a[0].name
    assert_nothing_raised { a.to_yaml }
  end  
  
  def test_ensure_subtable_works_with_unnamed_tables
     a = Table([], :data => [[1,2,3],[4,5,6]])
     b = a.sub_table { |r| (r[0] % 2).zero? } 
     assert_equal Table([], :data => [[4,5,6]]), b
  end  
  
  def test_ensure_appending_records_works_with_unnamed_tables
     a = Table([], :data => [[1,2,3],[4,5,6]])
     a << Ruport::Data::Record.new([7,8,9])
     assert_equal Table([], :data => [[1,2,3],[4,5,6],[7,8,9]]),a
  end

  def test_ensure_propagate_record_class
    a = Table(:record_class => DuckRecord)
    assert_equal DuckRecord, a.record_class

    b = a.dup
    assert_equal DuckRecord, b.record_class
  end

  def test_ensure_reorder_raises_on_bad_reorder_use
    a = Table() << [1,2,3] << [4,5,6]
    assert_raise(ArgumentError) { a.reorder("a","b","c") }
    assert_raise(ArgumentError) { a.reorder(%w[a b c]) }
    assert_raise(ArgumentError) { a.reorder(2,1,0) }
  end    

  class MySubClass < Ruport::Data::Table; end
  
  def test_ensure_table_subclasses_render_properly
    a = MySubClass.new
    a << [1,2,3] << [4,5,6]
    assert_equal("1,2,3\n4,5,6\n",a.as(:csv))
  end

end    

class TestTableAppendOperations < Test::Unit::TestCase
  def test_append_record  
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << Ruport::Data::Record.new([1,2,3], :attributes => %w[a b c])
    assert_equal([1,2,3],table[0].to_a)
    assert_equal(%w[a b c],table[0].attributes)
    rec = table[0].dup
    rec.attributes = %w[a b c d]
    assert_raise(NoMethodError) { table << Object.new }
  end
  
  def test_append_hash
    table = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    table << { "a" => 7, "c" => 9, "b" => 8 }
    
    assert_equal Table(%w[a b c], :data => [[1,2,3],[4,5,6],[7,8,9]]), table
  end

  def test_append_table
    first = Ruport::Data::Table.new :column_names => %w[a b c],
      :data => [[1,2,3],[4,5,6]]
    
    second = Ruport::Data::Table.new :column_names => %w[a b c],
      :data => [[7,8,9],[10,11,12]]
      
    combo = first + second
    
    assert_equal Ruport::Data::Table.new(:column_names => %w[a b c], 
      :data => [[1,2,3],[4,5,6],[7,8,9],[10,11,12]]), combo
  end  
  
  def test_append_chain
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << [1,2,3] << [4,5,6] << [7,8,9] 
    assert_equal 3, table.length
    assert_equal 5, table[1].b
  end  
end

class TestTableFormattingHooks < Test::Unit::TestCase
  
  def test_to_hack_takes_args
    a = Table(%w[hello mr crowley]) << %w[would you like] << %w[one red cat]
    
    assert_equal "would,you,like\none,red,cat\n",
                 a.to_csv(:show_table_headers => false)
    
    assert_equal "would,you,like\none,red,cat\n",
                 a.to_csv { |r| r.options.show_table_headers = false }    
                 
    assert_equal "would\tyou\tlike\none\tred\tcat\n",
                 a.to_csv(:show_table_headers => false) { |r|
                   r.options.format_options = { :col_sep => "\t" }
                 }
  end     
  
  def test_to_hack
    table = Ruport::Data::Table.new :column_names => %w[a b], 
                                    :data => [[1,2],[3,4],[5,6]]
    assert_equal("a,b\n1,2\n3,4\n5,6\n",table.to_csv)
    assert_raises(Ruport::Controller::UnknownFormatError) { table.to_nothing }
  end

  def test_as_throws_proper_errors
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    assert_nothing_raised { a.as(:csv) }
    assert_nothing_raised { a.to_csv }
    assert_raises(Ruport::Controller::UnknownFormatError) { a.as(:nothing) }
    assert_raises(Ruport::Controller::UnknownFormatError) { a.to_nothing }
  end
    
end

class TestTableColumnOperations < Test::Unit::TestCase
  
  def test_column
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    assert_equal [3,6], a.column(2)
    assert_equal [2,5], a.column("b") 
    
    assert_raise(ArgumentError) { a.column("d") }  
    assert_raise(ArgumentError) { a.column(42) }
    
    a = Table([], :data => [[1],[2],[3],[4]])
    assert_equal [1,2,3,4], a.column(0)  
  end
    
  def test_set_column_names
    a = Table([], :data => [[1,2,3],[4,5,6]])
    
    assert_equal([],a.column_names)
    assert_equal([[1,2,3],[4,5,6]],a.map { |r| r.to_a } )
                                                          
    a.column_names = %w[a b c]
    assert_equal(%w[a b c],a.column_names)
    a.each { |r| assert_equal(%w[a b c], r.attributes) }    
    assert_equal([[1,2,3],[4,5,6]],a.map { |r| r.to_a })
    
    a.column_names = %w[d e f]
    assert_equal(%w[d e f],a.column_names)
    a.each { |r| assert_equal(%w[d e f], r.attributes) }
    assert_equal([[1,2,3],[4,5,6]],a.map { |r| r.to_a })   
  end   
  
  def test_add_column
     a = Table(%w[a b], :data => [[1,2],[3,4],[5,6]])
     a.add_column("c")
     assert_equal Table(%w[a b c], :data => [[1,2,nil],[3,4,nil],[5,6,nil]]), a

     a = Table(%w[a b], :data => [[1,2],[3,4],[5,6]])
     a.add_column("c",:default => "x")
     assert_equal Table(%w[a b c], :data => [[1,2,'x'],[3,4,'x'],[5,6,'x']]), a    

     b = a.dup
     b.add_column("x",:before => "b")
     assert_equal Table(%w[a x b c],
      :data => [[1,nil,2,'x'],[3,nil,4,'x'],[5,nil,6,'x']]), b 

     b = a.dup
     b.add_column("x",:after => "b")
     assert_equal Table(%w[a b x c],
      :data => [[1,2,nil,'x'],[3,4,nil,'x'],[5,6,nil,'x']]), b  


     a.add_column("d") { |r| r[0]+r[1] }
     assert_equal Table(%w[a b c d],
      :data => [ [1,2,'x',3],[3,4,'x',7],[5,6,'x',11] ]), a

     a.add_column("x",:position => 1)
     assert_equal Table(%w[a x b c d],
      :data => [ [1,nil,2,'x',3],[3,nil,4,'x',7],[5,nil,6,'x',11] ]), a
  end

  def test_add_columns
    a = Table(%w[a b], :data => [[1,2],[3,4],[5,6]])
    a.add_columns(%w[c d])
    expected = Table(%w[a b c d],
      :data => [ [1,2,nil,nil],[3,4,nil,nil],[5,6,nil,nil] ])

    assert_equal expected, a                  

    a = Table(%w[a b], :data => [[1,2],[3,4],[5,6]])

    a.add_columns(%w[c d],:after => "a")

    expected = Table(%w[a c d b],
      :data => [ [1,nil,nil,2],[3,nil,nil,4],[5,nil,nil,6], ])                        

    assert_equal expected, a                                   

    a.add_columns(%w[x f],:before => "a")

    expected = Table(%w[x f a c d b],
      :data => [ [nil,nil,1,nil,nil,2],
                 [nil,nil,3,nil,nil,4],
                 [nil,nil,5,nil,nil,6] ])

    assert_equal expected, a       

    a = Table(%w[a b c], :data => [[1,2,0],[3,4,0],[5,6,0]])  

    a.add_columns(%w[x y],:default => 9, :position => 1)

    expected = Table(%w[a x y b c],
      :data => [[1,9,9,2,0],[3,9,9,4,0],[5,9,9,6,0]])  

    assert_equal expected, a

    a = Table(%w[a b], :data => [[1,2],[3,4],[5,6]])
    a.add_columns(%w[f x],:default => 0)

    expected = Table(%w[a b f x], :data => [[1,2,0,0],[3,4,0,0],[5,6,0,0]])
    assert_equal expected, a

    assert_raises(RuntimeError) do 
     a.add_columns(%w[a b]) { } 
    end
  end

  def test_remove_column
    a = Table(%w[a b c]) { |t| t << [1,2,3] << [4,5,6] }
    b = a.dup

    a.remove_column("b")
    assert_equal Table(%w[a c]) { |t| t << [1,3] << [4,6] }, a        

    b.remove_column(2)
    assert_equal Table(%w[a b]) { |t| t << [1,2] << [4,5] }, b
  end    

  def test_remove_columns
    a = Table(%w[a b c d]) { |t| t << [1,2,3,4] << [5,6,7,8] }
    b = a.dup
    a.remove_columns("b","d")
    assert_equal Table(%w[a c]) { |t| t << [1,3] << [5,7] }, a        
    b.remove_columns(%w[a c])
    assert_equal Table(%w[b d]) { |t| t << [2,4] << [6,8] }, b
  end   

  def test_rename_column
    a = Table(%w[a b]) { |t| t << [1,2] << [3,4] }
    a.rename_column("b","x")
    assert_equal Table(%w[a x]) { |t| t << [1,2] << [3,4] }, a
  end     

  def test_rename_columns
    a = Table(%w[a b]) { |t| t << [1,2] << [3,4] }
    a.rename_columns(%w[a b], %w[x y])
    assert_equal Table(%w[x y]) { |t| t << [1,2] << [3,4] }, a

    a = Table(%w[a b]) { |t| t << [1,2] << [3,4] }
    a.rename_columns("a"=>"x","b"=>"y")
    assert_equal Table(%w[x y]) { |t| t << [1,2] << [3,4] }, a

    a = Table(%w[a b]) { |t| t << [1,2] << [3,4] }
    assert_raise(ArgumentError) { a.rename_columns(%w[a b], %w[x]) }

    a = Table(%w[a b c]) { |t| t << [1,2,3] << [4,5,6] }
    a.rename_columns { |r| r.to_sym }
    assert_equal(a, Table(:a,:b,:c) { |t| t << [1,2,3] << [4,5,6] })

    a = Table(%w[a b c]) { |t| t << [1,2,3] << [4,5,6] }
    a.rename_columns(%w[a c]) { |r| r.to_sym }
    assert_equal(a, Table(:a,"b",:c) { |t| t << [1,2,3] << [4,5,6] })  
  end     

  def test_swap_column
    a = Table(%w[a b]) { |t| t << [1,2] << [3,4] }
    a.swap_column("a","b")
    assert_equal Table(%w[b a]) { |t| t << [2,1] << [4,3] }, a    
    a.swap_column(1,0)
    assert_equal  Table(%w[a b]) { |t| t << [1,2] << [3,4] }, a
  end      

  def test_replace_column
    a = Table(%w[a b c]) { |t| t << [1,2,3] << [4,5,6] }  
    a.replace_column("b","d") { |r| r.b.to_s }
    assert_equal Table(%w[a d c]) { |t| t << [1,"2",3] << [4,"5",6] }, a
    a.replace_column("d") { |r| r.d.to_i }
    assert_equal Table(%w[a d c]) { |t| t << [1,2,3] << [4,5,6] }, a
  end        
  
  # --- BUG TRAPS ------------------------------------ 
  
  def test_ensure_setting_column_names_changes_record_attributes
    table = Ruport::Data::Table.new :column_names => %w[a b c], 
      :data => [[1,2,3],[4,5,6]]
    
    assert_equal %w[a b c], table.column_names
    assert_equal %w[a b c], table.data[0].attributes
    assert_equal %w[a b c], table.data[1].attributes

    table.column_names = %w[d e f]

    assert_equal %w[d e f], table.column_names
    assert_equal %w[d e f], table.data[0].attributes
    assert_equal %w[d e f], table.data[1].attributes
  end   
  
  def test_ensure_setting_column_names_later_does_not_break_replace_column
    a = Table(%w[a b c], :data => [[1,2,3],[4,5,6]])
    a.replace_column("b","q") { |r| r.a + r.c }
    a.column_names = %w[d e f]
    assert_equal Table(%w[d e f], :data => [[1,4,3],[4,10,6]]), a

    a = Table([], :data => [[1,2,3],[4,5,6]])

    a.replace_column(1) { |r| r[0] + r[2] }

    a.column_names = %w[d e f]
    assert_equal Table(%w[d e f], :data => [[1,4,3],[4,10,6]]), a

    a = Table([], :data => [[1,2,3],[4,5,6]])

    a.replace_column(2) { |r| r[0] + 5 }

    a.column_names = %w[a b c]

    a.replace_column("b") { |r| r.a + 4 }
    a.replace_column("b","foo") { |r| r.b + 1 }

    assert_equal Table(%w[a foo c], :data => [[1,6,6],[4,9,9]]), a
  end 

  def test_ensure_renaming_a_missing_column_fails_silently
    a = Table(%w[a b c])
    assert_nothing_raised do
      a.rename_column("d", "z")
    end
  end

end  

class TestTableFromCSV < Test::Unit::TestCase
  
  def test_csv_load
    table = Ruport::Data::Table.load(File.join(TEST_SAMPLES,"data.csv"))
    assert_equal %w[col1 col2 col3], table.column_names
    rows = [%w[a b c],["d",nil,"e"]]
    table.each { |r| assert_equal rows.shift, r.to_a
                     assert_equal %w[col1 col2 col3], r.attributes }
    expected = Table(%w[a b c], :data => [%w[1 2 3],%w[4 5 6]])
    
    # ticket:94
    table = Ruport::Data::Table.load( File.join(TEST_SAMPLES,"data.tsv"), 
                                      :csv_options => { :col_sep => "\t" } )
    assert_equal expected, table 

    expected = ['c','e']
   
    table = Ruport::Data::Table.load( File.join(TEST_SAMPLES,"data.csv"),
      :csv_options => { :headers => true, :header_converters => :symbol }
      ) do |s,r|
        assert_equal expected.shift, r[:col3]
      end

    assert_equal [:col1,:col2,:col3], table.column_names

    expected = ['c','e']
   
    Ruport::Data::Table.load( File.join(TEST_SAMPLES,"data.csv"), 
                              :records => true ) do |s,r|
      assert_equal expected.shift, r.col3
      assert_kind_of Ruport::Data::Record, r
    end
     
    table = Ruport::Data::Table.load( File.join(TEST_SAMPLES, "data.csv"), 
                                     :has_names => false )
    assert_equal([],table.column_names)
    assert_equal(Table([],
      :data => [%w[col1 col2 col3],%w[a b c],["d",nil,"e"]]), table)
  end

  # ticket:76
  def test_parse
    assert_nothing_raised { 
      Ruport::Data::Table.parse("a,b,c\n1,2,3\n") 
    }
    
    table = Ruport::Data::Table.parse("a,b,c\n1,2,3\n4,5,6\n")
    expected = Table(%w[a b c], :data => [%w[1 2 3],%w[4 5 6]])
    
    table = Ruport::Data::Table.parse( "a\tb\tc\n1\t2\t3\n4\t5\t6\n", 
                                      :csv_options => { :col_sep => "\t" } )
    assert_equal expected, table 

    table = Ruport::Data::Table.parse( "a,b,c\n1,2,3\n4,5,6\n", 
                                       :has_names => false)
    assert_equal([],table.column_names)
    assert_equal(Table([], :data => [%w[a b c],%w[1 2 3],%w[4 5 6]]), table)
  end
  
  def test_csv_block_form
    expected = [%w[a b],%w[1 2],%w[3 4]]
    t = Ruport::Data::Table.send(:get_table_from_csv, 
                                 :parse, "a,b\n1,2\n3,4", 
                                 :has_names => false) do |s,r|
      assert_equal expected.shift, r
      s << r    
    end
    assert_equal Table([], :data => [%w[a b],%w[1 2],%w[3 4]]), t
  end         
  
  # - BUG TRAPS --------------------
  
  def test_ensure_using_csv_block_mode_works
    expected = [%w[a b],%w[1 2],%w[3 4]]
    t = Ruport::Data::Table.parse("a,b\n1,2\n3,4",:has_names => false) { |s,r|
      assert_equal expected.shift, r
      s << r    
      s << r
    }
    assert_equal Table([],
      :data => [%w[a b],%w[a b],%w[1 2], %w[1 2],%w[3 4],%w[3 4]]), t
    x = Ruport::Data::Table.load(File.join(TEST_SAMPLES,"data.csv")) { |s,r|
      assert_kind_of Ruport::Data::Feeder, s
      assert_kind_of Array, r
      s << r
      s << r
    }
    assert_equal 4, x.length
  end  
  
  def test_ensure_csv_loading_accepts_table_options
     a = Table(File.join(TEST_SAMPLES,"addressbook.csv"), 
                 :record_class => DuckRecord)
     a.each { |r| assert_kind_of(DuckRecord,r) }
  end    
  
  def test_ensure_table_from_csv_accepts_record_class_in_block_usage
    a = Table(File.join(TEST_SAMPLES,"addressbook.csv"),
                :record_class => DuckRecord, :records => true) do |s,r|
       assert_kind_of(DuckRecord,r) 
    end
  end
  
end

class TestTableKernelHack < Test::Unit::TestCase
  
  def test_simple
    assert_equal Ruport::Data::Table.new(:column_names => %w[a b c]),
      Table(%w[a b c])
    assert_equal Ruport::Data::Table.new(:column_names => %w[a b c]),
      Table("a","b","c")
    assert_equal Ruport::Data::Table.load(
                 File.join(TEST_SAMPLES,"addressbook.csv")),
                 Table(File.join(TEST_SAMPLES,"addressbook.csv"))
    assert_equal Ruport::Data::Table.load(
                   File.join(TEST_SAMPLES,"addressbook.csv"), :has_names => false),
                 Table(File.join(TEST_SAMPLES,"addressbook.csv"), :has_names => false) 
    Table("a","b","c") do |t|
      t << [1,2,3]
      assert_equal(
        Ruport::Data::Table.new(:column_names => %w[a b c], :data => [[1,2,3]]),
        t.data
      )
    end

    assert_equal Table("a"), Table(%w[a])
    assert_equal Table(:a), Table([:a])
  end

  def test_iterators
    Table(File.join(TEST_SAMPLES,"addressbook.csv")) do |s,r|
      assert_kind_of(Array,r)
      assert_kind_of(Ruport::Data::Feeder,s)
    end

    n = 0

    Table(:string => "a,b,c\n1,2,3\n4,5,6\n") do |s,r|
      assert_kind_of(Array,r)
      assert_kind_of(Ruport::Data::Feeder,s)
      n += 1
    end

    assert_equal 2, n
  end
  
  def test_with_file_arg
    assert_equal Table(File.join(TEST_SAMPLES,"addressbook.csv")),
                 Table(:file => File.join(TEST_SAMPLES,"addressbook.csv"))
  end
   
  def test_with_string_arg
    csv_string = "id,name\n1,Inky\n2,Blinky\n3,Clyde"
     
    assert_equal Ruport::Data::Table.parse(csv_string),
                 Table(:string => csv_string)
  end

  def test_ensure_table_hack_accepts_normal_constructor_args
    assert_equal Ruport::Data::Table.new(:column_names => %w[a b c]),
                 Table(:column_names => %w[a b c])
  end    
  
end
