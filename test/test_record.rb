require "test/unit"
require "ruport"


class TestRecord < Test::Unit::TestCase

  include Ruport::Data

  def setup
    @attributes = %w[a b c d]
    @record = Ruport::Data::Record.new [1,2,3,4], :attributes => @attributes 
  end

  def test_init
    record = Ruport::Data::Record.new [1,2,3,4]
    assert_equal 1, record[0]
    assert_equal 2, record[1]
    assert_equal 3, record[2]
    assert_equal 4, record[3]

    assert_equal 1, @record["a"]
    assert_equal 4, @record["d"]
    assert_equal 2, @record.b
    assert_equal 3, @record.c
  end
  
  def test_hash_constructor
    record = Ruport::Data::Record.new({:a => 1, :b => 2, :c => 3},{})
    assert_equal 1, record[:a]
    assert_equal 2, record[:b]
    assert_equal 3, record[:c]
  end
  
  def test_hash_constructor_with_attributes
    record = Record.new({:a => 1, :b => 2, :c => 3 }, :attributes => [:c,:b,:a])
    assert_equal 1, record[:a]
    assert_equal 2, record[:b]
    assert_equal 3, record[:c]
    
    assert_equal 3, record[0]
    assert_equal 2, record[1]
    assert_equal 1, record[2]
  end
  
  def test_brackets
    assert_equal 1, @record[0]
    assert_equal 2, @record[1]
    assert_equal 3, @record[2]
    assert_equal 4, @record[3]

    assert_equal 1, @record["a"]
    assert_equal 2, @record["b"]
    assert_equal 3, @record["c"]
    assert_equal 4, @record["d"]
  end
  
  def test_bracket_equals
    @record[1] = "godzilla"
    @record["d"] = "mothra"

    assert_equal @record[1], "godzilla"
    assert_equal @record["b"], "godzilla"

    assert_equal @record[3], "mothra"
    assert_equal @record["d"], "mothra"
  end
    
  def test_accessors
    assert_equal @record.a, @record["a"]
    assert_equal @record.b, @record["b"]
    assert_equal @record.c, @record["c"]
    assert_equal @record.d, @record["d"]
  end

  def test_attribute_setting
    @record.a = 10
    @record.b = 20
    assert_equal 10, @record.a
    assert_equal 20, @record.b
  end

  def test_to_a
    assert_equal [1,2,3,4], a = @record.to_a; a[0] = "q"
    assert_equal [1,2,3,4], @record.to_a
  end

  def test_to_h
    assert_nothing_raised { @record.to_h }
    assert_equal({ "a" => 1, "b" => 2, "c" => 3, "d" => 4 }, @record.to_h)
  end

  def test_equality

    dc  = %w[a b c d]
    dc2 = %w[a b c d]
    dc3 = %w[a b c]
    
    rec1 = Record.new [1,2,3,4]
    rec2 = Record.new [1,2,3,4]
    rec3 = Record.new [1,2]
    rec4 = Record.new [1,2,3,4], :attributes => dc
    rec5 = Record.new [1,2,3,4], :attributes => dc2
    rec6 = Record.new [1,2,3,4], :attributes => dc3
    rec7 = Record.new [1,2],     :attributes => dc
    
    [:==, :eql?].each do |op|
      assert   rec1.send(op, rec2)
      assert   rec4.send(op, rec5)
      assert ! rec1.send(op,rec3)
      assert ! rec1.send(op,rec4)
      assert ! rec6.send(op,rec7)
      assert ! rec3.send(op,rec4)
    end

  end

  def test_attributes
    assert_equal %w[a b c d], @record.attributes
    @record.attributes = %w[apple banana courier django]
    assert_equal %w[apple banana courier django], @record.attributes
  end

  def test_reordering
    r = @record.reorder "a","d","b","c"
    assert_equal [1,4,2,3], r.data
    assert_equal %w[a d b c], r.attributes

    assert_equal [1,2,3,4], @record.data
    assert_equal %w[a b c d], @record.attributes
    
    @record.reorder! "a","d","b","c"
    assert_equal [1,4,2,3], @record.data
    assert_equal %w[a d b c], @record.attributes

    @record.reorder! 3,1,2
    assert_equal [3,4,2], @record.data
    assert_equal %w[c d b], @record.attributes

    r.reorder! %w[a b c]
    assert_equal [1,2,3], r.data
    assert_equal %w[a b c], r.attributes

    assert_raise(ArgumentError) { r.reorder "foo" }
    assert_raise(ArgumentError) { r.reorder 0,5 }
    assert_nothing_raised { r.reorder 0 }
    assert_nothing_raised { r.reorder "a","b" }
  end

  def test_dup
    rec1 = Record.new [1,2,3,4], :attributes => %w[a b c d]
    rec2 = rec1.dup

    rec2.a = 5
    rec2["b"] = 7
    rec2[2] = 9

    rec2.tag(:apple)

    assert_equal [1,2,3,4], rec1.data
    assert_equal [5,7,9,4], rec2.data

    assert_equal [], rec1.tags
    assert_equal [:apple], rec2.tags
  end

  def test_records_with_same_attrs_and_data_hash_the_same
    r = Record.new :attributes => %w[a b], :data => [1,2]
    s = Record.new :attributes => %w[a b], :data => [1,2]
    assert_equal r.hash, s.hash
  end
  
  def test_records_with_differing_attrs_and_data_hash_differently
    r = Record.new :attributes => %w[a b], :data => [1,2]
    s = Record.new :attributes => %w[a b]
    assert r.hash != s.hash
    
    t = Record.new :attributes => %w[a b], :data => [1,3]
    assert r.hash != t.hash
  end
end
