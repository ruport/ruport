require "test/unit"
require "ruport"        

class TestRenderTextTable < Test::Unit::TestCase 
  
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
                  a.to_text(:alignment => :center) )

    tf = "+------------+\n"
    a.column_names = %w[a bark]     
    assert_equal("#{tf}|  a  | bark |\n#{tf}|  1  |  2   |\n"+
                 "| 300 |  4   |\n#{tf}", a.to_text(:alignment => :center) )   
  end

  def test_justified
    tf = "+----------+\n"
    a = [[1,'Z'],[300,'BB']].to_table
    
    # justified alignment can be set explicitly
    assert_equal "#{tf}|   1 | Z  |\n| 300 | BB |\n#{tf}", 
                 a.to_text(:alignment => :justified)    
    
    # justified alignment is also default             
    assert_equal "#{tf}|   1 | Z  |\n| 300 | BB |\n#{tf}", a.to_s      
  end

  def test_wrapping  
    a = [[1,2],[300,4]].to_table.to_text(:table_width => 10)
    assert_equal("+------->>\n|   1 | >>\n| 300 | >>\n+------->>\n",a)
  end  
  
  def test_ignore_wrapping
    a = [[1,2],[300,4]].to_table.to_text(:table_width => 10, 
                                         :ignore_table_width => true )
    assert_equal("+---------+\n|   1 | 2 |\n| 300 | 4 |\n+---------+\n",a)
  end 
  
  def test_render_empty_table
    assert_raise(Ruport::FormatterError) { [].to_table.to_text }
    assert_nothing_raised { Table(%w[a b c]).to_text }

    a = Table(%w[a b c]).to_text
    expected = "+-----------+\n"+
               "| a | b | c |\n"+
               "+-----------+\n"
    assert_equal expected, a
  end
                                             
  # -- BUG TRAPS ------------------------------

  def test_should_render_without_column_names
    a = [[1,2,3]].to_table.to_text
    expected = "+-----------+\n"+
               "| 1 | 2 | 3 |\n"+
               "+-----------+\n"
    assert_equal(expected,a)
  end
  
end
    

class TestRenderTextRow < Test::Unit::TestCase

  def test_row_basic
    actual = Ruport::Renderer::Row.render_text(:data => [1,2,3])
    assert_equal("| 1 | 2 | 3 |\n", actual)
  end

end
        

class TestRenderTextGroup < Test::Unit::TestCase

  def test_render_text_group
    group = Ruport::Data::Group.new(:name => 'test',
                                    :data => [ %w[is this more],
                                               %w[interesting red snapper]],
                                    :column_names => %w[i hope so])

    actual = Ruport::Renderer::Group.render_text(:data => group)
    expected = "test:\n\n"+
               "+------------------------------+\n"+
               "|      i      | hope |   so    |\n"+
               "+------------------------------+\n"+
               "| is          | this | more    |\n"+
               "| interesting | red  | snapper |\n"+
               "+------------------------------+\n"
    assert_equal(expected, actual)
  end

  def test_render_text_group_without_headers
   group = Ruport::Data::Group.new(:name => 'test',
                                   :data => [ %w[is this more],
                                              %w[interesting red snapper]],
                                   :column_names => %w[i hope so])
   
    actual = Ruport::Renderer::Group.render(:text, :data => group,
      :show_table_headers => false )
    expected = "test:\n\n"+
               "+------------------------------+\n"+
               "| is          | this | more    |\n"+
               "| interesting | red  | snapper |\n"+
               "+------------------------------+\n"
    assert_equal(expected, actual)
  end                                           
end       
       

class TestRenderTextGrouping < Test::Unit::TestCase

  def test_render_text_grouping
    table = Ruport::Data::Table.new(:data => [ %w[is this more],
                                               %w[interesting red snapper]],
                                    :column_names => %w[i hope so])
    grouping = Grouping(table, :by => "i")

    actual = Ruport::Renderer::Grouping.render(:text, :data => grouping)
    expected = "interesting:\n\n"+
               "+----------------+\n"+
               "| hope |   so    |\n"+
               "+----------------+\n"+
               "| red  | snapper |\n"+
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
                                               %w[interesting red snapper]],
                                    :column_names => %w[i hope so])
    grouping = Grouping(table, :by => "i")

    actual = Ruport::Renderer::Grouping.render(:text, :data => grouping,
      :show_table_headers => false)
    expected = "interesting:\n\n"+
               "+----------------+\n"+
               "| red  | snapper |\n"+
               "+----------------+\n\n"+
               "is:\n\n"+
               "+-------------+\n"+
               "| this | more |\n"+
               "+-------------+\n\n"
    assert_equal(expected, actual)
  end
  
end