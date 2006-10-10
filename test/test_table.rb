require "test/unit"
require "ruport"
begin; require "rubygems"; rescue LoadError; nil; end

class TestTable < Test::Unit::TestCase
  def test_constructors
    table = Ruport::Data::Table.new
    table2 = Ruport::Data::Table.new :column_names => %w[a b c]
    table3 = Ruport::Data::Table.new :data => [[1,2,3]]
    table4 = Ruport::Data::Table.new :column_names => %w[col1 col2 col3], 
                                     :data => [[1,2,3]]
    tables = [table,table2,table3,table4]
    tables.zip([nil,%w[a b c], nil, %w[col1 col2 col3]]).each do |t,n|
      assert_equal n, t.column_names
    end
    
    a = Ruport::Data::Record.new [1,2,3]
    assert a.respond_to?(:[])
    b = a.dup
    b.attributes = %w[col1 col2 col3]
    tables.zip([[],[],[a],[b]]).each { |t,n| assert_equal n, t.data }
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

  def test_sigma
    table = [[1,2],[3,4],[5,6]].to_table(%w[col1 col2])
    assert table.respond_to?(:sigma)
    assert table.respond_to?(:sum)
    assert_equal(9,table.sigma(0))
    assert_equal(9,table.sigma("col1"))
    assert_equal(21,table.sigma { |r| r.col1 + r.col2 })
  end

  def test_append_record  
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << Ruport::Data::Record.new([1,2,3], :attributes => %w[a b c])
    assert_equal([1,2,3],table[0].data)
    assert_equal(%w[a b c],table[0].attributes)
    rec = table[0].dup
    rec.attributes = %w[a b c d]
    assert_raise(ArgumentError) { table << rec }
    assert_raise(ArgumentError) { table << Object.new }
    assert_raise(ArgumentError) { table << [].to_table }
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

  def test_csv_load
    table = Ruport::Data::Table.load("test/samples/data.csv")
    assert_equal %w[col1 col2 col3], table.column_names
    rows = [%w[a b c],["d",nil,"e"]]
    table.each { |r| assert_equal rows.shift, r.data
                     assert_equal %w[col1 col2 col3], r.attributes }
  end

  def test_reorder
    table = Ruport::Data::Table.load("test/samples/data.csv")
    table.reorder! *%w[col1 col3]
    assert_equal %w[col1 col3], table.column_names
    rows = [%w[a c], %w[d e]]
    table.each { |r| assert_equal rows.shift, r.data
                     assert_equal %w[col1 col3], r.attributes }
    a = [[1,2,3],[4,5,6]].to_table(%w[a b c]).reorder 2,0
    rows = [[3,1],[6,4]]
    a.each { |r| assert_equal rows.shift, r.data 
                 assert_equal %w[c a], r.attributes }
    assert_equal %w[c a], a.column_names

    b = [[1,2,3],[4,5,6]].to_table(%w[a b c]).reorder(%w[a c])
    rows = [[1,3],[4,6]]
    b.each { |r| 
      assert_equal rows.shift, r.data
      assert_equal %w[a c], r.attributes 
      assert_equal b.column_names.object_id,
                   r.instance_eval{@attributes}.object_id
    }
  end

  def test_append_column
    a = [[1,2],[3,4],[5,6]].to_table(%w[a b])
    a.append_column(:name => "c")
    assert_equal [[1,2,nil],[3,4,nil],[5,6,nil]].to_table(%w[a b c]), a
    a = [[1,2],[3,4],[5,6]].to_table
    a.append_column 
    assert_equal [[1,2,nil],[3,4,nil],[5,6,nil]].to_table, a
    a = [[1,2],[3,4],[5,6]].to_table(%w[a b])
    a.append_column(:name => "c",:fill => "x")
    assert_equal [[1,2,'x'],[3,4,'x'],[5,6,'x']].to_table(%w[a b c]), a
    a.append_column(:name => "d") { |r| r.to_a.join("|") }
    assert_equal( 
    [ [1,2,'x','1|2|x'],
      [3,4,'x',"3|4|x"],
      [5,6,'x','5|6|x']].to_table(%w[a b c d]), a)
    
  end

  def test_remove_column
    a = [[1,2],[3,4],[5,6]].to_table(%w[a b])
    b = a.dup

    b.remove_column("b")
    assert_equal [[1],[3],[5]].to_table(%w[a]), b
    a.append_column(:name => "c")
    assert_not_equal [[1,2],[3,4],[5,6]].to_table(%w[a b]), a 
    a.remove_column(:name => "c")
    assert_equal [[1,2],[3,4],[5,6]].to_table(%w[a b]), a 
    assert_raises(ArgumentError){a.remove_column(:name => "frank")}
    a.remove_column(0)
    assert_equal [[2],[4],[6]].to_table(%w[b]), a
    assert_equal %w[b], a.column_names
    a = [[1,2],[3,4],[5,6]].to_table
    a.remove_column(0)
    assert_equal [[2],[4],[6]].to_table, a
  end

  def test_split
    table = Ruport::Data::Table.new :column_names => %w[c1 c2 c3]
    table << ['a',2,3]
    table << ['d',5,6]
    table << ['a',4,5]
    table << ['b',3,4]
    table << ['d',9,10]

    group = table.split :group => "c1"
    assert group.respond_to?(:each_group)
    expected = %w[a d b]

    group.each_group { |g| assert_equal(expected.shift, g) }

    t = table.reorder("c2","c3")

    data = [[t[0],t[2]],[t[1],t[4]],[t[3]]]
    c1 = Ruport::Data::Record.new data, :attributes => %w[a d b]
    assert_equal c1.a, group.a.to_a
    assert_equal c1.d, group.d.to_a
    assert_equal c1.b, group.b.to_a

    table << ['a',2,7]
    table << ['d',9,11]

    group = table.split :group => %w[c1 c2]
    assert group.respond_to?(:each_group)
    expected = %w[a_2 d_5 a_4 b_3 d_9]

    group.each_group { |g| assert_equal(expected.shift, g) }

    t = table.reorder("c3")
    data = [[t[0],t[5]],[t[1]],[t[2]],[t[3]],[t[4],t[6]]]

    c1 = Ruport::Data::Record.new data, :attributes => %w[a_2 d_5 a_4 b_3 d_9]  
    
    assert_equal c1.a_2, group.a_2.to_a
    assert_equal c1.d_5, group.d_5.to_a
    assert_equal c1.a_4, group.a_4.to_a
    assert_equal c1.b_3, group.b_3.to_a
    assert_equal c1.d_9, group.d_9.to_a
    
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
  
  def test_to_set
    table = Ruport::Data::Table.new :column_names => %w[a b], 
                                    :data => [[1,2],[3,4],[5,6]]
    a = table.to_set
    b = Ruport::Data::Set.new :data => [table[1],table[0],table[2]] 

    assert_equal a,b
  end
  
  def test_array_hack
    t = [[1,2],[3,4],[5,6]].to_table 
    assert_instance_of Ruport::Data::Table, t
    assert_equal nil, t.column_names
    assert_equal Ruport::Data::Record.new([3,4]), t[1]
    t = [[1,2],[3,4],[5,6]].to_table :column_names => %w[a b]
    table = Ruport::Data::Table.new :column_names => %w[a b], 
                                    :data => [[1,2],[3,4],[5,6]]
    
    assert_equal t, table 
    
    # test short form
    table2 = [[1,2],[3,4],[5,6]].to_table %w[a b]
  
    assert_equal table, table2

  end

end
