#!/usr/local/bin/ruby -w

require "test/unit"
require "ruport"

class TestDataRow < Test::Unit::TestCase

  include Ruport
  
  def setup
    @rows = DataSet.new
    @rows.fields = %w[ foo bar ]
    @rows << [ 1 , 2 ]
    @rows << [ 3 , 4 ]
    @rows << [ 5 , 6 ]
    @rows << { "foo" => 7, "bar" => 8 }
    @rows << [ 9, 10 ]
  end

  def test_to_s
    assert_equal("[1,2]",@rows[0].to_s)
  end

  def test_tagging
    @rows[0].tag_as :foo
    assert_equal(true, @rows[0].has_tag?(:foo) )
    assert_equal( false,@rows[1].has_tag?(:foo) )
    assert_equal(false,@rows[0].has_tag?(:bar) )
    assert_equal({:foo => true},@rows[0].tags)
    @rows[0].tag_as :apple
    assert_equal({:foo => true, :apple => true},@rows[0].tags)
    assert_equal({},@rows[2].tags)
  end

  def test_constructor
    row  = Ruport::DataRow.new(%w[a b c], :data => [1,2,3])
    row2 = Ruport::DataRow.new(%w[a b c], :data => {"a" => 1, "b" => 2, "c" => 3})
    row3 = Ruport::DataRow.new(%w[a b c], :data => row2)
    row4 = Ruport::DataRow.new(%w[a b c], {:data => row3, :tags => [:awesome, :cool]})
    
    assert_equal(row, row2)
    assert_equal(row2, row3)
    
    assert_equal(%w[a b c], row.fields)
    assert_equal(1, row[0])
    assert_equal(1, row["a"])
    assert_equal(2, row[1])
    assert_equal(2, row["b"])
    assert_equal(3, row[2])
    assert_equal(3, row["c"])
    assert_equal([:awesome,:cool], row4.tags)
    
  end

  def test_brackets
    r1 = @rows[0]
    r2 = @rows[3]

    assert_equal( 1, r1[0] )
    assert_equal( 2, r1[1] )
    assert_equal( 1, r1["foo"] )
    assert_equal( 2, r1["bar"] )

    assert_equal( 7, r2[0] )
    assert_equal( 8, r2["bar"] )
    assert_equal( 8, r2[:bar] )

    r1[1] = "apple"
    r1[:foo] = "banana"

    assert_equal( r1["foo"], "banana" )
    assert_equal( r1[:bar], "apple" )
    
    assert_nothing_raised { r1[:apples] }
    assert_equal( r1[:apples], nil )
  end

  def test_equality
    assert( Ruport::DataRow.new(%w[ a b ], :data => [1,2]) == 
            Ruport::DataRow.new(%w[ a b ], :data => [1,2]) )
    assert( Ruport::DataRow.new(%w[ a b ], :data => [1,2]) !=
            Ruport::DataRow.new(%w[ c d ], :data => [1,2]) )
    a = Ruport::DataRow.new(%w[ a b c ], :data => [1,2,3])
    a.tag_as :apple
    b = Ruport::DataRow.new(%w[ a b c ], :data => [1,2,3])
    assert( a == b )
    assert( a.eql?(b) )

  end
  
  def test_addition
    row1  = Ruport::DataRow.new %w[ a b c ], :data => [1,2,3]
    row2 = Ruport::DataRow.new %w[ d e f ], :data => [4,5,6]
    
    expected = Ruport::DataRow.new %w[ a b c d e f ], :data => [1,2,3,4,5,6]
    
    assert_equal( expected, row1 + row2 ) 
  end
  
  def test_clone 
    row1 = Ruport::DataRow.new %w[ a b c ], :data => [1,2,3]
    row2 = row1.clone

    assert( row1.object_id != row2.object_id )
    row1.tag_as :original
    assert( row1.has_tag?(:original) )
    assert( ! row2.has_tag?(:original) )
  end

  #FIXME: add edge cases
  def test_to_h
    row1 = Ruport::DataRow.new %w[ a b c ], :data => [1,2,3]
    assert_instance_of(Hash,row1.to_h)
    assert_equal({ "a" => 1, "b" => 2, "c" => 3},row1.to_h)
  end

  def test_ensure_arrays_not_modified
    arr = [1,2,3]
    row1 = Ruport::DataRow.new %w[ a b c ], :data => arr
    assert_equal( [1,2,3], arr )
  end

end
    
