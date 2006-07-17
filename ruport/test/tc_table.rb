require "test/unit"
require "ruport"

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
    b = a.dup
    b.attributes = %w[col1 col2 col3]
    tables.zip([[],[],[a],[b]]).each { |t,n| assert_equal n, t.data }
  end

  def test_append_record  
    table = Ruport::Data::Table.new :column_names => %w[a b c]
    table << Ruport::Data::Record.new([1,2,3], :attributes => %w[a b c])
    assert_equal([1,2,3],table[0].data)
    assert_equal(%w[a b c],table[0].attributes)
    rec = table[0].dup
    rec.attributes = %w[a b c d]
    assert_raise(ArgumentError) { table << rec }
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
  end

end
