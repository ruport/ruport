class TextPluginTest < Test::Unit::TestCase
  
  def test_basic

    tf = "+-------+\n"
    
    a = [[1,2],[3,4]].to_table.to_text
    assert_equal("#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}",a)

    a = [[1,2],[3,4]].to_table(%w[a b]).to_text
    assert_equal("#{tf}| a | b |\n#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}", a)
    
  end

  #def test_max_col_width
  #  a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
  #  a.active_plugin.calculate_max_col_widths
  #  assert_equal(3,a.active_plugin.max_col_width[0])
  #  assert_equal(1,a.active_plugin.max_col_width[1])

  #  a.data = [[1,2],[300,4]].to_table(:column_names => %w[a ba])
  #  a.active_plugin.calculate_max_col_widths
  #  assert_equal(3,a.active_plugin.max_col_width[0])
  #  assert_equal(2,a.active_plugin.max_col_width[1])

  #  a.data = [[1,2],[3,40000]].to_table(:column_names => %w[foo bazz])
  #  a.active_plugin.calculate_max_col_widths
  #  assert_equal(3,a.active_plugin.max_col_width[0])
  #  assert_equal(5,a.active_plugin.max_col_width[1])  
  #end

  #def test_hr
  #  a = Format.table_object :plugin => :text, :data => [[1,2],[300,4]]
  #  a.active_plugin.calculate_max_col_widths
  #  assert_equal("+---------+\n",a.active_plugin.hr)


  #  a.data = [[1,2],[3,40000]].to_table(:column_names => %w[foo bazz])
  #  a.active_plugin.calculate_max_col_widths
  #  assert_equal "+-------------+\n", a.active_plugin.hr
    
  #end

  def test_centering
    tf = "+---------+\n" 

    a = [[1,2],[300,4]].to_table
    assert_equal("#{tf}|  1  | 2 |\n| 300 | 4 |\n#{tf}",a.to_text)

    tf = "+------------+\n"
    a.column_names = %w[a bark]
    assert_equal("#{tf}|  a  | bark |\n#{tf}|  1  |  2   |\n"+
                 "| 300 |  4   |\n#{tf}",a.to_text)
    
  end

  def test_wrapping  
    a = [[1,2],[300,4]].to_table.as(:text) { |r|
      r.layout { |l| l.table_width = 10 }
    }

    assert_equal("+------->>\n|  1  | >>\n| 300 | >>\n+------->>\n",a)
  end


  def test_make_sure_this_damn_column_names_bug_dies_a_horrible_death!
    a = [[1,2,3]].to_table.to_text
    expected = "+-----------+\n"+
               "| 1 | 2 | 3 |\n"+
               "+-----------+\n"
    assert_equal(expected,a)

  end

  def test_raise_error_on_empty_table
    assert_raise(RuntimeError) { [].to_table.to_text }
    assert_raise(RuntimeError) { [].to_table(%w[a b c]).to_text }
  end

  
end
