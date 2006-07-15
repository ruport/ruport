require "test/unit"
require "ruport"

class DummyCollection
  attr_accessor :column_names
end


class RecordTest < Test::Unit::TestCase

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
  
end
