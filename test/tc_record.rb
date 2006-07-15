require "test/unit"
require "ruport"

class DummyCollection
  attr_accessor :column_names
end


class RecordTest < Test::Unit::TestCase

  def test_init
    record = Ruport::Data::Record.new [1,2,3,4]
    assert_equal 1, record[0]
    assert_equal 2, record[1]
    assert_equal 3, record[2]
    assert_equal 4, record[3]

    collection = DummyCollection.new
    collection.column_names = %w[a b c d]

    record = Ruport::Data::Record.new [1,2,3,4], :collection => collection
    assert_equal 1, record["a"]
    assert_equal 4, record["d"]
    assert_equal 2, record.b
    assert_equal 3, record.c

  end

end
