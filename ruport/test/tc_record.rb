require "test/unit"
require "ruport"

class DummyCollection
  def initialize(column_names=nil)
    self.column_names = column_names
  end
  attr_accessor :column_names
end


class RecordTest < Test::Unit::TestCase

  include Ruport::Data

  def setup
    @collection = DummyCollection.new
    @collection.column_names = %w[a b c d]
    
    @record = Ruport::Data::Record.new [1,2,3,4], :collection => @collection    
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

    dc  = DummyCollection.new %w[a b c d]
    dc2 = DummyCollection.new %w[a b c d]
    dc3 = DummyCollection.new %w[a b c]
    
    rec1 = Record.new [1,2,3,4]
    rec2 = Record.new [1,2,3,4]
    rec3 = Record.new [1,2]
    rec4 = Record.new [1,2,3,4], :collection => dc
    rec5 = Record.new [1,2,3,4], :collection => dc2
    rec6 = Record.new [1,2,3,4], :collection => dc3
    rec7 = Record.new [1,2],     :collection => dc
    
    [:==, :eql?].each do |op|
      assert   rec1.send(op, rec2)
      assert   rec4.send(op, rec5)
      assert ! rec1.send(op,rec3)
      assert ! rec1.send(op,rec4)
      assert ! rec6.send(op,rec7)
      assert ! rec3.send(op,rec4)
    end

  end

end
