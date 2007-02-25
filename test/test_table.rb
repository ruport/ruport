require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end


class Person < Ruport::Data::Record
  
  def name
    first_name + " " + last_name
  end

end

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

    t = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    t[0].tag :foo
    t[1].tag :bar
    table_from_records = t.data.to_table(t.column_names)
    assert_equal Set.new([:foo]), table_from_records[0].tags
    assert_equal Set.new([:bar]), table_from_records[1].tags
    end
    
    a = Ruport::Data::Record.new [1,2,3]
    b = Ruport::Data::Record.new [1,2,3], :attributes => %w[col1 col2 col3]
    tables.zip([[],[],[a],[b]]).each { |t,n| 
      assert_equal n, t.data }
  end    
  
  def test_column
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    assert_equal [3,6], a.column(2)
    assert_equal [2,5], a.column("b") 
    
    assert_raise(ArgumentError) { a.column("d") }  
    assert_raise(ArgumentError) { a.column(42) }
    
    a = [[1],[2],[3],[4]].to_table
    assert_equal [1,2,3,4], a.column(0)
    
  end
  
  def test_set_column_names
    a = [[1,2,3],[4,5,6]].to_table
    
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

  def test_rows_with
    table = [[1,2,3],[1,3,4],[7,8,9]].to_table(%w[a b c])
    
    assert_equal([table[0],table[1]],table.rows_with("a" => 1))
    assert_equal([table[1]],table.rows_with("a" => 1, "b" => 3))
    assert_equal([table[0]],table.rows_with(:a => 1, :b => 2))
    assert_equal([table[2]], table.rows_with_b(8))
    assert_equal [table[1]], table.rows_with(%w[a b]) { |a,b| [a,b] == [1,3] }
  end

  def test_append_record  
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << Ruport::Data::Record.new([1,2,3], :attributes => %w[a b c])
    assert_equal([1,2,3],table[0].to_a)
    assert_equal(%w[a b c],table[0].attributes)
    rec = table[0].dup
    rec.attributes = %w[a b c d]
    assert_raise(ArgumentError) { table << Object.new }
    assert_raise(ArgumentError) { table << [].to_table }
  end
  
  def test_append_hash
    table = [[1,2,3],[4,5,6]].to_table(%w[a b c])
    table << { "a" => 7, "c" => 9, "b" => 8 }
    
    assert_equal [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c]), table
  end

  def test_sigma
    table = [[1,2],[3,4],[5,6]].to_table(%w[col1 col2])
    assert table.respond_to?(:sigma)
    assert table.respond_to?(:sum)
    assert_equal(9,table.sigma(0))
    assert_equal(9,table.sigma("col1"))
    assert_equal(21,table.sigma { |r| r.col1 + r.col2 })
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
  
  def test_sub_table
    table = [ [1,2,3,4],[5,6,7,9],
              [10,11,12,13],[14,15,16,17] ].to_table(%w[a b c d])
   
    assert_equal [[6,7],[11,12]].to_table(%w[b c]), 
                 table.sub_table(%w[b c],1..-2) 
                 
    assert_equal [[3,4,1],[7,9,5]].to_table(%w[c d a]),  
                 table.sub_table(%w[c d a]) { |r| r.a < 10 }    
                 
    assert_equal [[1,3],[5,7],[10,12],[14,16]].to_table(%w[a c]),  
                 table.sub_table(%w[a c])
     
    assert_equal [[10,11,12,13],[14,15,16,17]].to_table(%w[a b c d]),      
                 table.sub_table { |r| r.c > 10 }
                  
  end

  def test_csv_load
    table = Ruport::Data::Table.load("test/samples/data.csv")
    assert_equal %w[col1 col2 col3], table.column_names
    rows = [%w[a b c],["d",nil,"e"]]
    table.each { |r| assert_equal rows.shift, r.to_a
                     assert_equal %w[col1 col2 col3], r.attributes }
    expected = [%w[1 2 3],%w[4 5 6]].to_table(%w[a b c])
    
    # ticket:94
    table = Ruport::Data::Table.load( "test/samples/data.tsv", 
                                      :csv_options => { :col_sep => "\t" } )
    assert_equal expected, table 
    
    table = Ruport::Data::Table.load("test/samples/data.csv", :has_names => false)
    assert_equal([],table.column_names)
    assert_equal([%w[col1 col2 col3],%w[a b c],["d",nil,"e"]].to_table, table)
    
  end

  # ticket:76
  def test_parse
    
    assert_nothing_raised { 
      Ruport::Data::Table.parse("a,b,c\n1,2,3\n") 
    }
    
    table = Ruport::Data::Table.parse("a,b,c\n1,2,3\n4,5,6\n")
    expected = [%w[1 2 3],%w[4 5 6]].to_table(%w[a b c])
    
    table = Ruport::Data::Table.parse( "a\tb\tc\n1\t2\t3\n4\t5\t6\n", 
                                      :csv_options => { :col_sep => "\t" } )
    assert_equal expected, table 

    table = Ruport::Data::Table.parse( "a,b,c\n1,2,3\n4,5,6\n", 
                                       :has_names => false)
    assert_equal([],table.column_names)
    assert_equal([%w[a b c],%w[1 2 3], %w[4 5 6]].to_table, table) 
    
  end
  
  def test_csv_block_form
    expected = [%w[a b],%w[1 2],%w[3 4]]
    t = Ruport::Data::Table.send(:get_table_from_csv, 
                                 :parse, "a,b\n1,2\n3,4", 
                                 :has_names => false) do |s,r|
      assert_equal expected.shift, r
      s << r    
    end
    assert_equal [%w[a b],%w[1 2],%w[3 4]].to_table, t
  end

  def test_reorder
    table = Ruport::Data::Table.load("test/samples/data.csv")
    table.reorder *%w[col1 col3]
    assert_equal %w[col1 col3], table.column_names
    rows = [%w[a c], %w[d e]]
    table.each { |r| assert_equal rows.shift, r.to_a
                     assert_equal %w[col1 col3], r.attributes }
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c]).reorder 2,0
    rows = [[3,1],[6,4]]
    a.each { |r| assert_equal rows.shift, r.to_a 
                 assert_equal %w[c a], r.attributes }
    assert_equal %w[c a], a.column_names

    b = [[1,2,3],[4,5,6]].to_table(%w[a b c]).reorder(%w[a c])
    rows = [[1,3],[4,6]]
    b.each { |r| 
      assert_equal rows.shift, r.to_a
      assert_equal %w[a c], r.attributes 
      assert_equal b.column_names.object_id,
                   r.instance_eval{@attributes}.object_id
    }
  end

  def test_add_column
    
    a = [[1,2],[3,4],[5,6]].to_table(%w[a b])
    a.add_column("c")
    assert_equal [[1,2,nil],[3,4,nil],[5,6,nil]].to_table(%w[a b c]), a
    
    a = [[1,2],[3,4],[5,6]].to_table(%w[a b])
    a.add_column("c",:default => "x")
    assert_equal [[1,2,'x'],[3,4,'x'],[5,6,'x']].to_table(%w[a b c]), a    
    
    b = a.dup
    b.add_column("x",:before => "b")
    assert_equal [[1,nil,2,'x'],
                  [3,nil,4,'x'],
                  [5,nil,6,'x']].to_table(%w[a x b c]), b 
                  
    b = a.dup
    b.add_column("x",:after => "b")
    assert_equal [[1,2,nil,'x'],
                  [3,4,nil,'x'],
                  [5,6,nil,'x']].to_table(%w[a b x c]), b  
    
    
    a.add_column("d") { |r| r[0]+r[1] }
    assert_equal( 
    [ [1,2,'x',3],
      [3,4,'x',7],
      [5,6,'x',11] ].to_table(%w[a b c d]), a)
    
    a.add_column("x",:position => 1)
    assert_equal(
    [ [1,nil,2,'x',3],
      [3,nil,4,'x',7],
      [5,nil,6,'x',11] ].to_table(%w[a x b c d]), a)          
    
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
  end
  
  def test_append_chain
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << [1,2,3] << [4,5,6] << [7,8,9] 
    assert_equal 3, table.length
    assert_equal 5, table[1].b
  end

  def test_to_hack
    table = Ruport::Data::Table.new :column_names => %w[a b], 
                                    :data => [[1,2],[3,4],[5,6]]
    assert_equal("a,b\n1,2\n3,4\n5,6\n",table.to_csv)
  end
  
  
  def test_sort_rows_by
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << [1,2,3] << [6,1,8] << [9,1,4]

    sorted_table_a = Ruport::Data::Table.new :column_names => %w[a b c]
    sorted_table_a << [1,2,3] << [6,1,8] << [9,1,4]

    sorted_table_b = Ruport::Data::Table.new :column_names => %w[a b c]
    sorted_table_b << [6,1,8] << [9,1,4] << [1,2,3]
    
    sorted_table_bc = Ruport::Data::Table.new :column_names => %w[a b c]
    sorted_table_bc << [9,1,4] << [6,1,8] << [1,2,3]
  
    assert_equal sorted_table_a,  table.sort_rows_by {|r| r['a']}
    assert_equal sorted_table_b,  table.sort_rows_by(['b'])
    assert_equal sorted_table_bc, table.sort_rows_by(['b', 'c'])
  end

  def test_array_hack
    t = [[1,2],[3,4],[5,6]].to_table 
    assert_instance_of Ruport::Data::Table, t
    assert_equal [], t.column_names
    table = Ruport::Data::Table.new :column_names => %w[a b], 
                                    :data => [[1,2],[3,4],[5,6]]
    
    table2 = [[1,2],[3,4],[5,6]].to_table %w[a b]
  
    assert_equal table, table2

  end    
                   
  # for those in a meta-mood (mostly just a collection coverage )
  def test_table_to_table
   a = [[1,2,3]].to_table 
   assert_kind_of Ruport::Data::Table, a
   assert_equal [[1,2,3]].to_table(%w[a b c]), 
                a.to_table(:column_names => %w[a b c])
  end

  def test_record_class
    a = Ruport::Data::Table.new( :column_names => %w[first_name last_name c], 
                                 :data =>[['joe','loop',3],['jim','blue',6]],
                                 :record_class => Person )
    assert_equal a, [
      ['joe','loop',3],['jim','blue',6]
    ].to_table(%w[first_name last_name c])
    assert_kind_of Person, a[0]
    assert_equal 'joe loop', a[0].name
    assert_equal 'jim blue', a[1].name

    b = Table(%w[first_name last_name], :record_class => Person ) do |t|
      t << { 'first_name' => 'joe', 'last_name' => 'frasier' }
      t << { 'first_name' => 'brian', 'last_name' => 'black' }
    end

    b.each { |r| assert_kind_of Person, r }

    assert_equal ['joe frasier', 'brian black'],
                 b.map { |r| r.name }

  end


  ## BUG Traps -------------------------------------------------
  
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
  
  def test_ensure_table_creation_allows_record_coercion
    table = [[1,2,3],[4,5,6],[7,8,9]].to_table
    table_with_names = [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c])
   
    a,b,c = nil
    assert_nothing_raised { a = table.to_a.to_table(%w[a b c]) }
    assert_nothing_raised { b = table.to_a.to_table(%w[d e f]) }
    assert_nothing_raised { c = table_with_names.to_a.to_table }

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
  
  def test_ensure_using_csv_block_mode_works
    expected = [%w[a b],%w[1 2],%w[3 4]]
    t = Ruport::Data::Table.parse("a,b\n1,2\n3,4",:has_names => false) { |s,r|
      assert_equal expected.shift, r
      s << r    
      s << r
    }
    assert_equal [%w[a b],%w[a b],%w[1 2], %w[1 2],
                  %w[3 4],%w[3 4]].to_table, t
    x = Ruport::Data::Table.load("test/samples/data.csv") { |s,r|
      assert_kind_of Ruport::Data::Table, s
      assert_kind_of Array, r
      s << r
      s << r
    }
    assert_equal 4, x.length
  end
  
  # bug found with paul novak 2007.01.17
  def test_ensure_tags_preserved_in_subtable
    a = [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c])
    a[1].tag(:foo)
    a.create_group("bar") { |r| r.b < 6 }
    assert_equal Set.new(["grp_bar"]), a.group("bar")[0].tags
    assert_equal Set.new([:foo,"grp_bar"]), a.group("bar")[1].tags
  end
  
  def test_ensure_coerce_sum
    s = [["1"],["3"],["5"] ].to_table
    t = [["1.23"],["1.5"]].to_table
    
    assert_equal(9,s.sum(0))
    assert_equal(2.73,t.sum(0))
  end
  
  #Ticket #142          
  def test_ensure_constructor_dups_record_tags
    a = [[1,2,3],[4,5,6],[7,8,9]].to_table(%w[a b c])
    b = a.dup    
    
    a[0].tag :foo
    assert_equal Set.new([]), b[0].tags
    assert_equal Set.new([:foo]),a[0].tags
    
    b[1].tag :bar
    assert_equal Set.new([]), a[1].tags
    assert_equal Set.new([:bar]), b[1].tags
  end

  def test_ensure_serializable
    a = [].to_table
    assert_nothing_raised { a.to_yaml }
    a = Table(%w[first_name last_name],:record_class => Person) { |t| 
      t << %w[joe loop] 
    }
    assert_equal "joe loop", a[0].name
    assert_nothing_raised { a.to_yaml }
  end  
  
  def test_ensure_subtable_works_with_unnamed_tables
     a = [[1,2,3],[4,5,6]].to_table
     b = a.sub_table { |r| (r[0] % 2).zero? } 
     assert_equal [[4,5,6]].to_table, b
  end  
  
  def test_ensure_appending_records_works_with_unnamed_tables
     a = [[1,2,3],[4,5,6]].to_table
     a << Ruport::Data::Record.new([7,8,9])
     assert_equal [[1,2,3],[4,5,6],[7,8,9]].to_table,a
  end

end

class TestTableKernelHack < Test::Unit::TestCase
  
  def test_simple
    assert_equal [].to_table(%w[a b c]), Table(%w[a b c]) 
    assert_equal [].to_table(%w[a b c]), Table("a","b","c")
    assert_equal Ruport::Data::Table.load("test/samples/addressbook.csv"),
                 Table("test/samples/addressbook.csv")
    assert_equal Ruport::Data::Table.load(
                   "test/samples/addressbook.csv", :has_names => false),
                 Table('test/samples/addressbook.csv', :has_names => false) 
    Table("a","b","c") do |t|
      t << [1,2,3]
      assert_equal([[1,2,3]].to_table(%w[a b c]), t)
    end

    assert_equal Table("a"), Table(%w[a])
    assert_equal Table(:a), Table([:a])
  end
  
   def test_with_file_arg
     assert_equal Table("test/samples/addressbook.csv"),
                  Table(:file => "test/samples/addressbook.csv")
   end
   
   def test_with_string_arg
     csv_string = "id,name\n1,Inky\n2,Blinky\n3,Clyde"
     
     assert_equal Ruport::Data::Table.parse(csv_string),
                  Table(:string => csv_string)
   end
  
end
