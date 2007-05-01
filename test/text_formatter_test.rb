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

  def test_row_basic
    actual = Ruport::Renderer::Row.render_text { |r| r.data = [1,2,3] }
    assert_equal("| 1 | 2 | 3 |\n", actual)
  end


  def test_centering
    tf = "+---------+\n" 

    a = [[1,2],[300,4]].to_table
    assert_equal( "#{tf}|  1  | 2 |\n| 300 | 4 |\n#{tf}",
                  a.as(:text) { |e| e.options.alignment = :center })

    tf = "+------------+\n"
    a.column_names = %w[a bark]     
    assert_equal("#{tf}|  a  | bark |\n#{tf}|  1  |  2   |\n"+
                 "| 300 |  4   |\n#{tf}",
                  a.as(:text) { |e| e.options.alignment = :center })
    
  end

  def test_justified
    tf = "+----------+\n"
    a = [[1,'Z'],[300,'BB']].to_table
    assert_equal "#{tf}|   1 | Z  |\n| 300 | BB |\n#{tf}", a.to_s
  end

  def test_wrapping  
    a = [[1,2],[300,4]].to_table.as(:text) { |r|
      r.options { |l| l.table_width = 10 }
    }

    assert_equal("+------->>\n|   1 | >>\n| 300 | >>\n+------->>\n",a)
  end  
  
  def test_ignore_wrapping
      a = [[1,2],[300,4]].to_table.as(:text) { |r|
      r.options { |l| 
        l.table_width = 10 
        l.ignore_table_width = true
      }
    }

    assert_equal("+---------+\n|   1 | 2 |\n| 300 | 4 |\n+---------+\n",a)
  end

  def test_make_sure_this_damn_column_names_bug_dies_a_horrible_death!
    a = [[1,2,3]].to_table.to_text
    expected = "+-----------+\n"+
               "| 1 | 2 | 3 |\n"+
               "+-----------+\n"
    assert_equal(expected,a)

  end

  def test_render_text_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [ %w[is this more],
                                               %w[interesting chris carter]],
                                    :column_names => %w[i hope so])

    actual = Ruport::Renderer::Group.render(:text, :data => group)
    expected = "test:\n\n"+
               "+------------------------------+\n"+
               "|      i      | hope  |   so   |\n"+
               "+------------------------------+\n"+
               "| is          | this  | more   |\n"+
               "| interesting | chris | carter |\n"+
               "+------------------------------+\n"
    assert_equal(expected, actual)
  end

  def test_render_text_group_without_headers
   group = Ruport::Data::Group.new(:name => 'test',
                                   :data => [ %w[is this more],
                                               %w[interesting chris carter]],
                                   :column_names => %w[i hope so])
   
    actual = Ruport::Renderer::Group.render(:text, :data => group,
      :show_table_headers => false )
    expected = "test:\n\n"+
               "+------------------------------+\n"+
               "| is          | this  | more   |\n"+
               "| interesting | chris | carter |\n"+
               "+------------------------------+\n"
    assert_equal(expected, actual)
  end

  def test_raise_error_on_empty_table
    assert_raise(RuntimeError) { [].to_table.to_text }
    assert_raise(RuntimeError) { [].to_table(%w[a b c]).to_text }
  end

  def test_render_text_grouping
    table = Ruport::Data::Table.new(:data => [ %w[is this more],
                                               %w[interesting chris carter]],
                                    :column_names => %w[i hope so])
    grouping = Grouping(table, :by => "i")

    actual = Ruport::Renderer::Grouping.render(:text, :data => grouping)
    expected = "interesting:\n\n"+
               "+----------------+\n"+
               "| hope  |   so   |\n"+
               "+----------------+\n"+
               "| chris | carter |\n"+
               "+----------------+\n\n"+
               "is:\n\n"+
               "+-------------+\n"+
               "| hope |  so  |\n"+
               "+-------------+\n"+
               "| this | more |\n"+
               "+-------------+\n\n"
    assert_equal(expected, actual)  
    
    actual = grouping.to_s
    assert_equal(expected,actual)
  end

  def test_render_text_grouping_without_headers
    table = Ruport::Data::Table.new(:data => [ %w[is this more],
                                               %w[interesting chris carter]],
                                    :column_names => %w[i hope so])
    grouping = Grouping(table, :by => "i")

    actual = Ruport::Renderer::Grouping.render(:text, :data => grouping,
      :show_table_headers => false)
    expected = "interesting:\n\n"+
               "+----------------+\n"+
               "| chris | carter |\n"+
               "+----------------+\n\n"+
               "is:\n\n"+
               "+-------------+\n"+
               "| this | more |\n"+
               "+-------------+\n\n"
    assert_equal(expected, actual)
  end
  
end
