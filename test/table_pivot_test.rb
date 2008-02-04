#!/usr/bin/env ruby -w   
require File.join(File.expand_path(File.dirname(__FILE__)), "helpers")

class TablePivotSimpleCaseTest < Test::Unit::TestCase

  def setup
    table = Table('a', 'b', 'c')
    table << [1,3,6]
    table << [1,4,7]
    table << [2,3,8]
    table << [2,4,9]
    @pivoted = table.pivot('b', :group_by => 'a', :values => 'c')
  end

  def test_produces_correct_columns
    assert_equal(['a', 3, 4], @pivoted.column_names)
  end

  def test_produces_correct_full_table
    expected = Table("a",3,4) { |t| t << [1,6,7] << [2,8,9] }
    assert_equal(expected, @pivoted)
  end

end

class PivotConvertRowOrderToGroupOrderTest < Test::Unit::TestCase

  def convert(src)
    Ruport::Data::Table::Pivot.new(
      nil, nil, nil, nil
    ).convert_row_order_to_group_order(src)
  end

  def setup
    @group = mock('group')
    @row = mock('row')
    @group.stubs(:[]).with(0).returns(@row)
  end

  def test_bare_field_name
    converted = convert(:field_name)
    @row.expects(:[]).with(:field_name)
    converted.call(@group)
  end

  def test_array_of_field_names
    converted = convert([:field1, :field2])
    @row.stubs(:[]).with(:field1).returns('f1val')
    @row.stubs(:[]).with(:field2).returns('f2val')
    assert_equal(['f1val', 'f2val'], converted.call(@group))
  end

  def test_proc_operating_on_row
    converted = convert(proc {|row| row[:field1] })
    @row.stubs(:[]).with(:field1).returns('f1val')
    assert_equal('f1val', converted.call(@group))
  end

  def test_nil
    assert_equal(nil, convert(nil))
  end

end

class PivotPreservesOrdering < Test::Unit::TestCase

  def test_group_column_entries_preserves_order_of_occurrence
    table = Table('group', 'a', 'b')
    [
      [1, 0, 0],
      [9, 0, 0],
      [1, 0, 0],
      [9, 0, 0],
      [1, 0, 0],
      [8, 0, 0],
      [1, 0, 0]
    ].each {|e| table << e}
    assert_equal([1,9,8], 
       Ruport::Data::Table::Pivot.
       new(table, 'group', 'a', 'b').group_column_entries)
  end

  def test_resulting_columns_preserve_ordering_of_rows
    table = Table('group', 'a', 'b', 'c')
    [
      [200,   1, 2, 1],
      [200,   4, 5, 2],
      [200,   5, 0, 3],
      [100,   1, 8, 4],
      [100,   4,11, 5]
    ].each {|e| table << e}
    assert_equal(
      [1,4,5],
      Ruport::Data::Table::Pivot.new(
        table, 'group', 'a', 'b', :pivot_order => ['c']
      ).columns_from_pivot)
  end

  def test_preserves_ordering
    table = Table('group', 'a', 'b', 'c')
    [
      [200,   1, 2, 3],
      [200,   4, 5, 6],
      [100,   1, 8, 9],
      [100,   4,11,12]
    ].each {|e| table << e}
    pivoted = table.pivot('a', :group_by => 'group', :values => 'b')
    expected = Table("group",1,4) { |t| t << [200,2,5] << [100,8,11] }
    assert_equal(expected, pivoted)
  end

  def test_preserves_ordering_on_calculated_column
    table = Table('group', 'a')
    [
      [1, 1], [2, 2], [3, 3]
    ].each {|e| table << e}
    table.add_column('pivotme') {|row| 10 - row.group.to_i}
    pivoted = table.pivot('pivotme', :group_by => 'group', :values => 'a', 
                                     :pivot_order => :name)
    assert_equal(['group', 7, 8, 9], pivoted.column_names)
  end

  def test_preserves_ordering_on_calculated_column_with_proc_pivot_order
    table = Table('group', 'a')
    [
      [1, 1], [2, 2], [3, 3]
    ].each {|e| table << e}
    table.add_column('pivotme') {|row| 10 - row.group.to_i}
    pivoted = table.pivot('pivotme', :group_by => 'group', :values => 'a', 
                                     :pivot_order => proc {|row, pivot| pivot })
    assert_equal(['group', 7, 8, 9], pivoted.column_names)
  end

end
