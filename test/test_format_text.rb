require "test/unit"
require "ruport"
class TestFormatText < Test::Unit::TestCase
  
  def test_basic

    tf = "+-------+\n"
    
    a = [[1,2],[3,4]].to_table.to_text
    assert_equal("#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}",a)

    a = [[1,2],[3,4]].to_table(%w[a b]).to_text
    assert_equal("#{tf}| a | b |\n#{tf}| 1 | 2 |\n| 3 | 4 |\n#{tf}", a)
    
  end


  def test_centering
    tf = "+---------+\n" 

    a = [[1,2],[300,4]].to_table
    assert_equal( "#{tf}|  1  | 2 |\n| 300 | 4 |\n#{tf}",
                  a.as(:text) { |e| e.layout.alignment = :center })

    tf = "+------------+\n"
    a.column_names = %w[a bark]     
    assert_equal("#{tf}|  a  | bark |\n#{tf}|  1  |  2   |\n"+
                 "| 300 |  4   |\n#{tf}",
                  a.as(:text) { |e| e.layout.alignment = :center })
    
  end

  def test_justified
    tf = "+----------+\n"
    a = [[1,'Z'],[300,'BB']].to_table
    assert_equal "#{tf}|   1 | Z  |\n| 300 | BB |\n#{tf}", a.to_s
  end

  def test_wrapping  
    a = [[1,2],[300,4]].to_table.as(:text) { |r|
      r.layout { |l| l.table_width = 10 }
    }

    assert_equal("+------->>\n|   1 | >>\n| 300 | >>\n+------->>\n",a)
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
