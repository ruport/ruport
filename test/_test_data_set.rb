#!/usr/local/bin/ruby -w

require "test/unit"
require "ruport"

class TestDataSet < Test::Unit::TestCase
  
  include Ruport
    
  def setup
    @data = DataSet.new
    @data.fields = %w[ col1 col2 col3 ]
    @data.default = ""
    @data << %w[ a b c ] << { "col1" => "d", "col3" => "e"}
  end

  def test_new
    fields = %w[ col1 col2 col3 ]
    my_data = DataSet.new(fields)
    assert_equal(fields,my_data.fields)

    my_filled_data = DataSet.new( fields, :data => [[1,2,3],[4,5,6]] )
    
    assert_equal( [[1,2,3],[4,5,6]], my_filled_data.map { |r| r.to_a } )

    hash_filling = [ { "col1" => 9, "col2" => 6, "col3" => 0 },
                     { "col1" => 54, "col3" => 1 } ]
    
    my_filled_data = DataSet.new(fields, :data => hash_filling)
    
    assert_equal( [[9,6,0],[54,nil,1]], my_filled_data.map { |r| r.to_a } )
   
    cloned_set = @data.clone
   
    assert_equal( [ %w[a b c], ["d","","e"] ], cloned_set.map { |r| r.to_a } )
  end
  
  def test_fields 
    assert_equal(%w[ col1 col2 col3 ], @data.fields )
  end

  def test_default
    @data.default = "x"
    @data << { }
    assert_equal(  ['x','x','x'],
                    @data[2].to_a )
  end

  def test_rename_columns
    @data.rename_columns "col1" => "Column 1", 
                         "col2" => "Column 2", 
                         "col3" => "Column 3"
    assert_equal %w[Column\ 1 Column\ 2 Column\ 3], @data.fields
    @data.each do |r|
      assert_equal %w[Column\ 1 Column\ 2 Column\ 3], r.fields
    end
    assert_equal "b", @data[0]["Column 2"]
    assert_equal "e", @data[1]["Column 3"]
    @data.rename_columns %w[one two three]
    assert_equal %w[one two three], @data.fields
    @data.each do |r|
      assert_equal %w[one two three], r.fields
    end
  end

  def test_delete_if
    @data.delete_if { |r| r.any? { |e| e.empty? } }
    assert_equal([%w[a b c]],@data.to_a)
  end
      
  def test_brackets
    row0 = { "col1" => "a", "col2" => "b", "col3" => "c" }
    row1 = { "col1" => "d", "col2" => "", "col3" => "e" }
    row0.each do |key,value|
      assert_equal( value, @data[0][key] )
    end
    row1.each do |key,value|
      assert_equal( value, @data[1][key] )
    end       
  end

  def test_eql?
    data2 = DataSet.new
    data2.fields = %w[ col1 col2 col3 ]
    data2.default = ""
    data2 << %w[ a b c ]
    data2 << { "col1" => "d", "col3" => "e" }

    #FIXME: This looks like some shady discrete math assignment
    assert(@data.eql?(data2) && data2.eql?(@data)) 
    data2 << [2, 3, 4]
    assert(!( @data.eql?(data2) || data2.eql?(@data) ))
    @data << [2, 3, 4]
    assert(@data.eql?(data2) && data2.eql?(@data))
    @data << [8, 9, 10]
    assert(!( @data.eql?(data2) || data2.eql?(@data) ))
    data2 << [8, 9, 10]
    assert(@data.eql?(data2) && data2.eql?(@data)) 
  end

  def test_shaped_like?
    a = DataSet.new
    a.fields = %w[ col1 col2 col3 ]
    assert(@data.shaped_like?(a))
    assert(a.shaped_like?(@data))
  end
 
  def test_union
    a = DataSet.new
    a.fields = %w[ col1 col2 col3 ]
    a << %w[ a b c ]
    a << %w[ x y z ]
    b = a | @data
    assert_kind_of(DataSet, b)
    assert_equal(b.data.length, 3)
    assert_equal([ %w[a b c], %w[x y z], ["d","","e"] ], b.to_a)
    assert_equal((a | @data), a.union(@data))
  end

  def test_difference
    a = DataSet.new
    a.fields = %w[ col1 col2 col3 ]
    a << %w[ a b c ]
    a << %w[ x y z ]
    b = a - @data
    assert_kind_of(DataSet, b)
    assert_equal(b.data.length, 1)
    assert_equal([ %w[x y z] ], b.to_a)
    assert_equal((a - @data), a.difference(@data))
  end
  
  def test_intersection
    a = DataSet.new
    a.fields = %w[ col1 col2 col3 ]
    a << %w[ a b c ]
    a << %w[ x y z ]
    b = a & @data
    assert_kind_of(DataSet, b)
    assert_equal(b.data.length, 1)
    assert_equal([ %w[a b c] ], b.to_a)
    assert_equal((a & @data), a.intersection(@data))
  end

  def test_concatenation
    a = DataSet.new
    a.fields = %w[ col1 col2 col3 ]
    a << %w[ x y z ]
    newdata = @data.concat(a)
    assert_equal([ %w[a b c], ["d","","e"], %w[x y z] ], newdata.to_a)
  end
  
  def test_append_datarow
    row = DataRow.new(%w[ x y z ], :data => %w[ col1 col2 col3 ])
    @data << row
    assert_equal(@data[2], row)
  end

  def test_append_datarows
    row = DataRow.new(%w[ x y z ], :data => %w[ col1 col2 col3 ])
    row2 = DataRow.new(%w[ u v w ], :data => %w[ col1, col2, col3 ])
    @data << [row, row2]
    assert_equal(@data[2], row)
    assert_equal(@data[3], row2)
  end
  
  def test_empty?
    a = DataSet.new
    a.fields = %w[a b c]
    assert_equal(true,a.empty?)
    assert_equal(false,@data.empty?)
    
    a << [1,2,3]
    assert_equal(false,a.empty?)
  end

  def test_length
    assert_equal(2, @data.length)
    @data << [1,2,3]
    assert_equal(3, @data.length)
  end

  def test_load
    loaded_data = DataSet.load("test/samples/data.csv", :default => "")
    assert_equal(@data,loaded_data)

    loaded_data = DataSet.load("test/samples/data.csv", :has_names => false)
    
    assert_equal(nil,loaded_data.fields)
    assert_equal([%w[col1 col2 col3],%w[a b c],["d",nil,"e"]],loaded_data.to_a)
    assert_equal(%w[a b c],loaded_data[1].to_a)

    loaded_data = DataSet.load("test/samples/data.csv") do |set,row| 
      set << row if row.include? 'b' 
    end
    assert_equal([%w[a b c]],loaded_data.to_a)
  end

  def test_to_csv
    loaded_data = DataSet.load("test/samples/data.csv" )
    csv = loaded_data.to_csv
    assert_equal("col1,col2,col3\na,b,c\nd,,e\n",csv)
  end

  def test_to_html
    assert_equal("<table>\n\t\t<tr>\n\t\t\t<th>col1 </th>\n\t\t\t"+
                 "<th>col2 </th>\n\t\t\t<th>col3</th>\n\t\t</tr>\n"+
                 "\t\t<tr>\n\t\t\t<td>a</td>\n\t\t\t<td>b</td>\n\t\t\t"+
                 "<td>c</td>\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>d</td>\n\t"+
                 "\t\t<td>&nbsp;</td>\n\t\t\t<td>e</td>\n\t\t</tr>"+
                 "\n\t</table>", @data.to_html )
  end

  def test_select_columns

    b = @data.select_columns(0,2)
    assert_equal(%w[col1 col3], b.fields)
    assert_equal([%w[a c],%w[d e]],b.to_a)
    
    assert_equal( [["a"],["d"]],
                  @data.select_columns("col1").to_a )
    assert_equal( [["b"],[""]] , 
                  @data.select_columns("col2").to_a )
    assert_equal( [["c"],["e"]],
                  @data.select_columns("col3").to_a )
    assert_equal( [["a","b","c"],["d","","e"]],
                  @data.select_columns("col1","col2","col3").to_a )
    assert_equal( [["c","a"],["e","d"]],
                  @data.select_columns("col3","col1").to_a )

  end
 
  def test_select_columns!
    a = [[1,2],[3,4]].to_ds(%w[a b])
    a.select_columns!(*%w[b a])

    assert_equal(%w[b a],a.fields)
    assert_equal([[2,1],[4,3]],a.to_a)

    a.select_columns!('a')

    assert_equal(%w[a], a.fields)
    assert_equal([[1],[3]],a.to_a)

    a.select_columns!('a','q')
    assert_equal(%w[a q], a.fields)
    assert_equal([[1,nil],[3,nil]],a.to_a)

    a[0]['q'] =2
    assert_equal([[1,2],[3,nil]],a.to_a)
    
  end

  def test_as
    data = DataSet.new
    data.fields = %w[ col1 col2 col3]
    data << %w[ a b c]
    data << %w[ d e f]
    assert_equal("col1,col2,col3\na,b,c\nd,e,f\n", 
                 data.as(:csv) )

    assert_equal("<table>\n\t\t<tr>\n\t\t\t<th>col1 </th>"+
                 "\n\t\t\t<th>col2 </th>\n\t\t\t<th>col3</th>"+
                 "\n\t\t</tr>\n\t\t<tr>\n\t\t\t<td>a</td>\n\t\t\t"+
                 "<td>b</td>\n\t\t\t<td>c</td>\n\t\t</tr>\n\t\t<tr>"+
                 "\n\t\t\t<td>d</td>\n\t\t\t<td>e</td>\n\t\t\t<td>f</td>"+
                 "\n\t\t</tr>\n\t</table>", data.as(:html) )
  end
  
  def test_sigma
    data = Ruport::DataSet.new(%w[x], :data => [[3],[5],[8],[2]])
    
    sum = data.sigma { |r| r["x"] if (r["x"] % 2).zero? }
    assert_equal(10, sum)

    sum = data.sigma { |r| r["x"] }
    assert_equal(18,sum)

    sum = data.sigma("x")
    assert_equal(18,sum)

    #check alias
    sum = data.sum { |r| r["x"] }
    assert_equal(18,sum) 
  end

  def test_add_columns
    d = @data.add_columns("a","b")
    assert_equal %w[col1 col2 col3 a b], d.fields
    assert_equal %w[col1 col2 col3], @data.fields
    assert_equal %w[col1 col2 col3 a b], d[0].fields
    assert_equal %w[col1 col2 col3], @data[0].fields
    assert_equal nil, d[0]["a"]
    d[0]["a"] = "foo"
    assert_equal %w[a b c foo] + [nil], d[0].to_a

    d.add_columns!("c")
    assert_equal %w[col1 col2 col3 a b c], d.fields
    assert_equal %w[col1 col2 col3 a b c], d[0].fields
  end

  def test_remove_columns
   
   d = @data.remove_columns(0)
   assert_equal(%w[col2 col3],d.fields)
   assert_equal([%w[b c],["","e"]], d.to_a)
    
   data = @data.remove_columns("col1","col3")
   assert_equal(["col2"],data.fields)
   assert_equal([["b"],[""]], data.to_a)

   data.remove_columns!("col2")
   assert_equal([],data.fields)
   assert(data.empty?)

   @data.remove_columns!("col1")
   assert_equal(%w[col2 col3], @data.fields)
  end

  def test_bracket_equals
    expected = DataRow.new(%w[col1 col2 col3], :data => %w[apple banana orange])
    
    raw = [ %w[apple banana orange],
            { "col1" => "apple", "col2" => "banana", "col3" => "orange" },
            DataRow.new(%w[col1 col2 col3], :data => %w[apple banana orange])
          ]
    raw.each do |my_row|
      @data[1] = my_row
      assert_instance_of(DataRow, @data[1])
      assert_equal(expected, @data[1])
    end

    assert_raise(ArgumentError) { @data[1] = "apple" }
  end
 
  def test_clone
    data2 = @data.clone
    assert( @data.object_id != data2.object_id )
    assert_equal( @data, data2 )
    data2 << %w[ f o o ]
    assert( @data != data2 )
    assert( data2 != @data )
  end

  def test_array_hack
    assert_nothing_raised {
      [ { :a => :b, :c => :d }, { :e => :f, :g => :h } ].to_ds(%w[a e])
    }
    assert_nothing_raised {
      [ [1,2,3], [4,5,6], [7,8,9] ].to_ds(%w[a b c])
    }
    assert_raise(ArgumentError) {
     %w[d e f].to_ds(%w[a b c])
    }
    assert_raise(TypeError) {
     [1,2,3].to_ds(%w[foo bar soup])
    }

    assert_equal( DataSet.new(%w[a b], :data => [[1,2],[3,4]]),
                  [[1,2],[3,4]].to_ds(%w[a b]) )

    assert_equal( DataSet.new(%w[a b], :data => [{ "a" => 1 },{ "b" => 2}]),
                  [{"a" => 1}, {"b" => 2}].to_ds(%w[a b]) )
    assert_equal( DataSet.new(%w[a b], :data => [DataRow.new(%w[a b], :data => [1,2])]),
                  [DataRow.new(%w[a b], :data => [1,2])].to_ds(%w[a b]) )
   
   # FIXME: Decide whether this test should pass or fail.               
   #  assert_equal( DataSet.new(%w[a b], [DataRow.new(%w[a b], [1,2])]),
   #               [DataRow.new(%w[a q], [1,2])].to_ds(%w[a b]) ) 
    
  end

  def test_append_chain
    data2 = DataSet.new(%w[col1 col2 col3])
    data2.default=""
    data2 << %w[ a b c ] << { "col1" => "d", "col3" => "e" }
    assert_equal @data, data2
  end
  
  def test_no_fields
    data2 = DataSet.new
    data2 << [1,2,3]
    data2 << [4,5,6]
    assert_equal([1,2,3],data2[0].to_a)
    assert_equal([4,5,6],data2[1].to_a)
  end
end
